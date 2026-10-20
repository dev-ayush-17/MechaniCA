import json
from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.cashfree.payment_gateway import CashfreePaymentGateway
from app.adapters.fake.audit_log import FakeAuditLog
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.coupon_service import FakeCouponService
from app.adapters.fake.notification_sender import RecordingNotifier
from app.adapters.fake.payment_gateway import FakePaymentGateway
from app.adapters.fake.payment_repository import FakePaymentRepository
from app.adapters.fake.wallet_service import FakeWalletService
from app.api.deps import (
    apply_gateway_event_dep,
    audit_log_dep,
    auth_verifier_dep,
    booking_repository_dep,
    clock_dep,
    coupon_service_dep,
    create_payment_dep,
    create_wallet_topup_dep,
    payment_gateway_dep,
    payment_repository_dep,
    refund_payment_dep,
    role_claims_dep,
    wallet_service_dep,
)
from app.application.apply_payment import ApplyGatewayEvent
from app.application.create_payment import CreatePayment
from app.application.refund_payment import RefundPayment
from app.application.wallet_topup import CreateWalletTopup
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.user import Role
from app.main import create_app

NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
UID = "cust_pay"
PHONE = "+919876543210"
TOKEN = f"fake:{UID}:{PHONE}"
KEY = "cccccccc-cccc-cccc-cccc-cccccccccccc"
ADDR = AddressSnapshot(
    id="addr_home",
    label="Home",
    line1="Boring Road",
    city="Patna",
    pincode="800001",
    lat=25.5941,
    lng=85.1376,
)


def _headers(key: str = KEY) -> dict[str, str]:
    return {"Authorization": f"Bearer {TOKEN}", "Idempotency-Key": key}


def _completed_booking() -> Booking:
    return Booking(
        id="b_pay",
        display_number="MCPAY001",
        customer_id=UID,
        vehicle_id="veh1",
        service_code="general_service",
        service_name="General Service",
        mode=BookingMode.INSTANT,
        urgency=Urgency.NORMAL,
        status=BookingStatus.COMPLETED,
        payment_method=PaymentMethod.UPI,
        address=ADDR,
        labor_paise=59900,
        parts_paise=0,
        fee_paise=4900,
        discount_paise=0,
        cgst_paise=5832,
        sgst_paise=5832,
        total_paise=76464,
        cancel_fee_paise=0,
        cancel_reason=None,
        scheduled_start=None,
        mechanic_id="mech",
        lines=(),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.bookings = FakeBookingRepository()
        self.payments = FakePaymentRepository()
        self.wallet = FakeWalletService()
        self.coupons = FakeCouponService(now=NOW)
        self.gateway = FakePaymentGateway()
        self.audit = FakeAuditLog()
        self.notifier = RecordingNotifier()
        self.clock = FakeClock(NOW)
        self.bookings.bookings["b_pay"] = _completed_booking()
        create = CreatePayment(
            payments=self.payments,
            bookings=self.bookings,
            gateway=self.gateway,
            wallet=self.wallet,
            coupons=self.coupons,
            clock=self.clock,
            gst_bps=1800,
        )
        apply = ApplyGatewayEvent(
            payments=self.payments,
            bookings=self.bookings,
            wallet=self.wallet,
            audit=self.audit,
            notifier=self.notifier,
            clock=self.clock,
        )
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[payment_repository_dep] = lambda: self.payments
        app.dependency_overrides[wallet_service_dep] = lambda: self.wallet
        app.dependency_overrides[coupon_service_dep] = lambda: self.coupons
        app.dependency_overrides[payment_gateway_dep] = lambda: self.gateway
        app.dependency_overrides[audit_log_dep] = lambda: self.audit
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[create_payment_dep] = lambda: create
        app.dependency_overrides[apply_gateway_event_dep] = lambda: apply
        app.dependency_overrides[create_wallet_topup_dep] = lambda: CreateWalletTopup(
            payments=self.payments, gateway=self.gateway, clock=self.clock
        )
        app.dependency_overrides[refund_payment_dep] = lambda: RefundPayment(
            payments=self.payments,
            gateway=self.gateway,
            wallet=self.wallet,
            clock=self.clock,
        )
        self.client = TestClient(app)


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_create_online_payment_is_pending(env: _Env) -> None:
    response = env.client.post(
        "/v1/payments",
        json={"bookingId": "b_pay", "method": "upi"},
        headers=_headers(),
    )
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "pending"
    assert body["amountPaise"] == 76464
    assert body["cashfree"]["paymentSessionId"]


def test_client_sdk_success_is_not_paid(env: _Env) -> None:
    created = env.client.post(
        "/v1/payments",
        json={"bookingId": "b_pay", "method": "upi"},
        headers=_headers(),
    )
    assert created.status_code == 201
    payment_id = created.json()["paymentId"]
    marked = env.client.post(
        f"/v1/payments/{payment_id}/mark-paid",
        json={"sdkStatus": "success"},
        headers=_headers(),
    )
    assert marked.status_code in {400, 401, 404, 405}
    polled = env.client.get(f"/v1/payments/{payment_id}", headers=_headers())
    assert polled.status_code == 200
    assert polled.json()["status"] == "pending"
    booking = env.bookings.bookings["b_pay"]
    assert booking.status is BookingStatus.COMPLETED


def test_signed_webhook_pays_once(env: _Env) -> None:
    created = env.client.post(
        "/v1/payments",
        json={"bookingId": "b_pay", "method": "upi"},
        headers=_headers(),
    )
    order_id = created.json()["cashfree"]["orderId"]
    raw = json.dumps(
        {
            "eventId": "evt_ok",
            "orderId": order_id,
            "amountPaise": 76464,
            "status": "success",
        }
    ).encode()
    response = env.client.post(
        "/v1/payments/cashfree/webhook",
        content=raw,
        headers=env.gateway.signed_headers(raw),
    )
    assert response.status_code == 200
    payment_id = created.json()["paymentId"]
    polled = env.client.get(f"/v1/payments/{payment_id}", headers=_headers())
    assert polled.json()["status"] == "paid"
    assert env.bookings.bookings["b_pay"].status is BookingStatus.PAID


def test_wallet_pay_debits_and_pays(env: _Env) -> None:
    from app.domain.wallet import LedgerDirection, LedgerEntry, LedgerReason

    env.wallet.entries[UID] = [
        LedgerEntry(
            id="credit1",
            user_id=UID,
            booking_id=None,
            direction=LedgerDirection.CREDIT,
            amount_paise=100000,
            reason=LedgerReason.TOPUP,
            created_at=NOW,
        )
    ]
    env.wallet._by_id["credit1"] = env.wallet.entries[UID][0]
    response = env.client.post(
        "/v1/payments",
        json={"bookingId": "b_pay", "method": "wallet"},
        headers=_headers(),
    )
    assert response.status_code == 201
    assert response.json()["status"] == "paid"
    assert response.json().get("cashfree") is None
    assert (env.wallet.entries[UID][-1].amount_paise) == 76464


def test_prod_refuses_sandbox_keys() -> None:
    try:
        CashfreePaymentGateway(
            app_id="TEST100",
            secret="TESTSECRET",  # noqa: S106
            api_url="https://sandbox.cashfree.com/pg",
            app_env="prod",
        )
    except ValueError as exc:
        assert "sandbox" in str(exc).lower()
    else:
        raise AssertionError("prod must refuse sandbox keys")


def test_admin_refund_once(env: _Env) -> None:
    created = env.client.post(
        "/v1/payments",
        json={"bookingId": "b_pay", "method": "upi"},
        headers=_headers(),
    )
    order_id = created.json()["cashfree"]["orderId"]
    raw = json.dumps(
        {
            "eventId": "evt_pay",
            "orderId": order_id,
            "amountPaise": 76464,
            "status": "success",
        }
    ).encode()
    env.client.post(
        "/v1/payments/cashfree/webhook",
        content=raw,
        headers=env.gateway.signed_headers(raw),
    )
    env.auth._claims[UID] = Role.ADMIN
    payment_id = created.json()["paymentId"]
    first = env.client.post(
        "/v1/admin/refunds",
        json={"paymentId": payment_id, "amountPaise": 76464},
        headers=_headers("dddddddd-dddd-dddd-dddd-dddddddddddd"),
    )
    assert first.status_code == 200
    assert first.json()["status"] == "refunded"
    second = env.client.post(
        "/v1/admin/refunds",
        json={"paymentId": payment_id, "amountPaise": 100},
        headers=_headers("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"),
    )
    assert second.status_code == 409
    assert second.json()["error"]["code"] == "already_refunded"
