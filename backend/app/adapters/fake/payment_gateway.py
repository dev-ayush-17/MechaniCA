"""Dev/test gateway. Signs webhooks with a test secret; no vendor SDK."""

from __future__ import annotations

import hashlib
import hmac
import json
import uuid

from app.domain.errors import InvalidWebhookSignature, NotFound
from app.domain.payment import GatewayEvent, GatewayOrder, PaymentOrder, RefundResult

TEST_WEBHOOK_SECRET = "mechupp_test_webhook_secret"  # noqa: S105 - test signing secret, not a credential


def sign_webhook(raw_body: bytes, secret: str = TEST_WEBHOOK_SECRET) -> str:
    return hmac.new(secret.encode(), raw_body, hashlib.sha256).hexdigest()


class FakePaymentGateway:
    """createOrder returns a fake session. Tests post signed events through verify."""

    def __init__(self, secret: str = TEST_WEBHOOK_SECRET) -> None:
        self.secret = secret
        self.orders: dict[str, GatewayOrder] = {}
        self.fetch_overrides: dict[str, GatewayOrder] = {}

    def sign(self, raw_body: bytes) -> str:
        return sign_webhook(raw_body, self.secret)

    def signed_headers(self, raw_body: bytes) -> dict[str, str]:
        return {"x-webhook-signature": self.sign(raw_body)}

    async def create_order(self, order: PaymentOrder) -> GatewayOrder:
        gid = f"order_{uuid.uuid4().hex[:12]}"
        created = GatewayOrder(
            gateway_order_id=gid,
            payment_session_id=f"session_{uuid.uuid4().hex[:12]}",
            amount_paise=order.amount_paise,
            status="created",
        )
        self.orders[gid] = created
        return created

    async def verify_webhook(self, headers: dict[str, str], raw_body: bytes) -> GatewayEvent:
        sig = headers.get("x-webhook-signature") or headers.get("X-Webhook-Signature") or ""
        expected = self.sign(raw_body)
        if not sig or not hmac.compare_digest(sig, expected):
            raise InvalidWebhookSignature("Webhook signature is invalid.")
        payload = json.loads(raw_body.decode())
        return GatewayEvent(
            event_id=str(payload["eventId"]),
            gateway_order_id=str(payload["orderId"]),
            amount_paise=int(payload["amountPaise"]),
            status=str(payload["status"]).lower(),
        )

    async def refund(
        self, gateway_order_id: str, amount_paise: int, idempotency_key: str
    ) -> RefundResult:
        if gateway_order_id not in self.orders and gateway_order_id not in self.fetch_overrides:
            raise NotFound("We could not find that order.")
        return RefundResult(
            refund_id=f"rf_{idempotency_key[:8]}",
            amount_paise=amount_paise,
            status="success",
        )

    async def fetch(self, gateway_order_id: str) -> GatewayOrder:
        if gateway_order_id in self.fetch_overrides:
            return self.fetch_overrides[gateway_order_id]
        order = self.orders.get(gateway_order_id)
        if order is None:
            raise NotFound("We could not find that order.")
        return order
