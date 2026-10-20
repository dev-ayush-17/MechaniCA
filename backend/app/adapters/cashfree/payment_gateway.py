"""Cashfree REST adapter. HMAC verify only; no card data is parsed or stored."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import urllib.error
import urllib.request
from decimal import Decimal
from typing import Any

from app.core.config import Env
from app.domain.errors import InvalidWebhookSignature, NotFound, Unavailable
from app.domain.payment import GatewayEvent, GatewayOrder, PaymentOrder, RefundResult


class CashfreePaymentGateway:
    def __init__(
        self,
        *,
        app_id: str,
        secret: str,
        api_url: str,
        app_env: Env,
    ) -> None:
        if app_env == "prod" and _is_sandbox(app_id, secret, api_url):
            raise ValueError("Production must not use Cashfree sandbox keys")
        self._app_id = app_id
        self._secret = secret
        self._api_url = api_url.rstrip("/")

    async def create_order(self, order: PaymentOrder) -> GatewayOrder:
        rupees = (Decimal(order.amount_paise) / Decimal(100)).quantize(Decimal("0.01"))
        payload = {
            "order_id": order.payment_id,
            "order_amount": str(rupees),
            "order_currency": order.currency,
            "customer_details": {
                "customer_id": order.customer_id,
                "customer_phone": order.customer_phone or "9999999999",
            },
        }
        body = _post(f"{self._api_url}/orders", payload, self._app_id, self._secret)
        return GatewayOrder(
            gateway_order_id=str(body.get("order_id") or order.payment_id),
            payment_session_id=str(body.get("payment_session_id") or ""),
            amount_paise=order.amount_paise,
            status=str(body.get("order_status") or "created").lower(),
        )

    async def verify_webhook(self, headers: dict[str, str], raw_body: bytes) -> GatewayEvent:
        lower = {k.lower(): v for k, v in headers.items()}
        timestamp = lower.get("x-webhook-timestamp", "")
        signature = lower.get("x-webhook-signature", "")
        signed = timestamp.encode() + raw_body
        expected = base64.b64encode(
            hmac.new(self._secret.encode(), signed, hashlib.sha256).digest()
        ).decode()
        if not signature or not hmac.compare_digest(signature, expected):
            raise InvalidWebhookSignature("Webhook signature is invalid.")
        payload = json.loads(raw_body.decode())
        data_raw = payload.get("data") if isinstance(payload, dict) else {}
        data = data_raw if isinstance(data_raw, dict) else {}
        order_raw = data.get("order")
        payment_raw = data.get("payment")
        order = order_raw if isinstance(order_raw, dict) else {}
        payment = payment_raw if isinstance(payment_raw, dict) else {}
        amount = order.get("order_amount") or 0
        paise = int((Decimal(str(amount)) * Decimal(100)).quantize(Decimal("1")))
        status_raw = str(payment.get("payment_status") or "")
        status = "success" if status_raw.upper() == "SUCCESS" else "failed"
        event_id = str(payload.get("event_time") or payload.get("type") or "cf")
        order_id = str(order.get("order_id") or "")
        cf_id = payment.get("cf_payment_id")
        if cf_id:
            event_id = str(cf_id)
        return GatewayEvent(
            event_id=event_id,
            gateway_order_id=order_id,
            amount_paise=paise,
            status=status,
        )

    async def refund(
        self, gateway_order_id: str, amount_paise: int, idempotency_key: str
    ) -> RefundResult:
        rupees = (Decimal(amount_paise) / Decimal(100)).quantize(Decimal("0.01"))
        body = _post(
            f"{self._api_url}/orders/{gateway_order_id}/refunds",
            {
                "refund_amount": str(rupees),
                "refund_id": idempotency_key,
                "refund_note": "admin",
            },
            self._app_id,
            self._secret,
        )
        return RefundResult(
            refund_id=str(body.get("refund_id") or idempotency_key),
            amount_paise=amount_paise,
            status=str(body.get("refund_status") or "success").lower(),
        )

    async def fetch(self, gateway_order_id: str) -> GatewayOrder:
        body = _get(f"{self._api_url}/orders/{gateway_order_id}", self._app_id, self._secret)
        amount = body.get("order_amount") or 0
        paise = int((Decimal(str(amount)) * Decimal(100)).quantize(Decimal("1")))
        return GatewayOrder(
            gateway_order_id=str(body.get("order_id") or gateway_order_id),
            payment_session_id=str(body.get("payment_session_id") or ""),
            amount_paise=paise,
            status=str(body.get("order_status") or "unknown").lower(),
        )


def _is_sandbox(app_id: str, secret: str, api_url: str) -> bool:
    blob = f"{app_id} {secret} {api_url}".upper()
    return "TEST" in blob or "SANDBOX" in blob


def _headers(app_id: str, secret: str) -> dict[str, str]:
    return {
        "Content-Type": "application/json",
        "x-client-id": app_id,
        "x-client-secret": secret,
        "x-api-version": "2023-08-01",
    }


def _post(url: str, payload: dict[str, Any], app_id: str, secret: str) -> dict[str, Any]:
    request = urllib.request.Request(  # noqa: S310 - HTTPS vendor URL from Settings
        url,
        data=json.dumps(payload).encode(),
        headers=_headers(app_id, secret),
        method="POST",
    )
    return _send(request)


def _get(url: str, app_id: str, secret: str) -> dict[str, Any]:
    request = urllib.request.Request(  # noqa: S310 - HTTPS vendor URL from Settings
        url, headers=_headers(app_id, secret), method="GET"
    )
    return _send(request)


def _send(request: urllib.request.Request) -> dict[str, Any]:
    try:
        with urllib.request.urlopen(request, timeout=15) as response:  # noqa: S310 - vendor URL from config
            raw = response.read()
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            raise NotFound("We could not find that order.") from exc
        raise Unavailable("Payment provider is unavailable. Try again.") from exc
    except urllib.error.URLError as exc:
        raise Unavailable("Payment provider is unavailable. Try again.") from exc
    parsed: object = json.loads(raw.decode() or "{}")
    return parsed if isinstance(parsed, dict) else {}
