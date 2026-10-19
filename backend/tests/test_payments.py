import json
from datetime import UTC, datetime, timedelta

import pytest

from app.adapters.fake.audit_log import FakeAuditLog
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.coupon_service import FakeCouponService
from app.adapters.fake.notification_sender import RecordingNotifier
from app.adapters.fake.payment_gateway import FakePaymentGateway
from app.adapters.fake.payment_repository import FakePaymentRepository
from app.adapters.fake.wallet_service import FakeWalletService
from app.application.apply_payment import ApplyGatewayEvent
from app.application.cash_confirm import ConfirmCash, MarkCashCollected
from app.application.reconcile_payments import ReconcilePendingPayments
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.coupon import CouponContext
from app.domain.errors import CouponRejected, InsufficientWallet, InvalidWebhookSignature
from app.domain.payment import (
    GatewayOrder,
    Payment,
    PaymentGatewayKind,
    PaymentReason,
    PaymentStatus,
)
from app.domain.user import Principal, Role
from app.domain.wallet import LedgerDirection, LedgerEntry, LedgerReason

NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
ADDR = AddressSnapshot(
    id="addr_home",
    label="Home",
    line1="Boring Road",
    city="Patna",
    pincode="800001",
    lat=25.5941,
    lng=85.1376,
)


def _booking() -> Booking:
    return Booking(
        id="b1",
        display_number="MCB10001",
        customer_id="cust",
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


def _payment(**overrides: object) -> Payment:
    fields: dict[str, object] = {
        "id": "pay1",
        "booking_id": "b1",
        "payer_id": "cust",
        "method": PaymentMethod.UPI,
        "amount_paise": 76464,
        "status": PaymentStatus.PENDING,
        "gateway": PaymentGatewayKind.CASHFREE,
        "gateway_order_id": "order_abc",
        "payment_session_id": "session_abc",
        "idempotency_key": "11111111-1111-1111-1111-111111111111",
        "reason": PaymentReason.BOOKING,
        "refunded_paise": 0,
        "cash_mechanic_marked_at": None,
        "cash_customer_marked_at": None,
        "cash_staff_note": None,
        "applied_event_ids": (),
        "created_at": NOW,
        "updated_at": NOW,
        "version": 1,
    }
    fields.update(overrides)
    return Payment(**fields)  # type: ignore[arg-type]


class _Env:
    def __init__(self) -> None:
        self.payments = FakePaymentRepository()
        self.bookings = FakeBookingRepository()
        self.wallet = FakeWalletService()
        self.audit = FakeAuditLog()
        self.notifier = RecordingNotifier()
        self.clock = FakeClock(NOW)
        self.gateway = FakePaymentGateway()
        self.coupons = FakeCouponService(now=NOW)
        self.apply = ApplyGatewayEvent(
            payments=self.payments,
            bookings=self.bookings,
            wallet=self.wallet,
            audit=self.audit,
            notifier=self.notifier,
            clock=self.clock,
        )


@pytest.fixture
def env() -> _Env:
    return _Env()


async def _seed_pending(env: _Env) -> Payment:
    await env.bookings.save(_booking())
    payment = _payment()
    await env.payments.insert(payment)
    return payment


def _body(amount: int = 76464, event_id: str = "evt_1", order_id: str = "order_abc") -> bytes:
    return json.dumps(
        {"eventId": event_id, "orderId": order_id, "amountPaise": amount, "status": "success"}
    ).encode()


@pytest.mark.asyncio
async def test_webhook_bad_signature_does_not_pay(env: _Env) -> None:
    payment = await _seed_pending(env)
    raw = _body()
    try:
        await env.gateway.verify_webhook({"x-webhook-signature": "deadbeef"}, raw)
    except InvalidWebhookSignature:
        pass
    else:
        raise AssertionError("bad signature must raise InvalidWebhookSignature")
    stored = await env.payments.get(payment.id)
    assert stored is not None
    assert stored.status is PaymentStatus.PENDING
    booking = await env.bookings.get("b1")
    assert booking is not None
    assert booking.status is BookingStatus.COMPLETED


@pytest.mark.asyncio
async def test_webhook_replay_is_noop(env: _Env) -> None:
    await _seed_pending(env)
    raw = _body()
    event = await env.gateway.verify_webhook(env.gateway.signed_headers(raw), raw)
    first = await env.apply.execute(event)
    second = await env.apply.execute(event)
    assert first.status is PaymentStatus.PAID
    assert second.status is PaymentStatus.PAID
    assert second.version == first.version
    booking = await env.bookings.get("b1")
    assert booking is not None
    assert booking.status is BookingStatus.PAID


@pytest.mark.asyncio
async def test_webhook_amount_mismatch_does_not_pay(env: _Env) -> None:
    await _seed_pending(env)
    raw = _body(amount=1)
    event = await env.gateway.verify_webhook(env.gateway.signed_headers(raw), raw)
    result = await env.apply.execute(event)
    assert result.status is PaymentStatus.PENDING
    assert "evt_1" in result.applied_event_ids
    assert any(e.action == "payment_mismatch" for e in env.audit.events)
    booking = await env.bookings.get("b1")
    assert booking is not None
    assert booking.status is BookingStatus.COMPLETED


@pytest.mark.asyncio
async def test_wallet_debit_cannot_go_negative(env: _Env) -> None:
    entry = LedgerEntry(
        id="wallet_pay1",
        user_id="cust",
        booking_id="b1",
        direction=LedgerDirection.DEBIT,
        amount_paise=100,
        reason=LedgerReason.BOOKING_PAYMENT,
        created_at=NOW,
    )
    try:
        await env.wallet.debit("cust", entry)
    except InsufficientWallet as exc:
        assert exc.code == "insufficient_wallet"
    else:
        raise AssertionError("debit below zero must raise InsufficientWallet")
    assert (await env.wallet.balance("cust")).paise == 0


@pytest.mark.asyncio
async def test_cash_requires_both_marks(env: _Env) -> None:
    await env.bookings.save(_booking())
    payment = _payment(
        method=PaymentMethod.CASH,
        gateway=PaymentGatewayKind.CASH,
        gateway_order_id=None,
        payment_session_id=None,
    )
    await env.payments.insert(payment)
    mechanic = Principal(user_id="mech", role=Role.MECHANIC, phone_e164="+919811111111")
    customer = Principal(user_id="cust", role=Role.CUSTOMER, phone_e164="+919876543210")
    marked = await MarkCashCollected(
        payments=env.payments,
        bookings=env.bookings,
        notifier=env.notifier,
        clock=env.clock,
    ).execute(mechanic, payment.id)
    assert marked.status is PaymentStatus.PENDING
    assert env.bookings.bookings["b1"].status is BookingStatus.COMPLETED
    paid = await ConfirmCash(payments=env.payments, bookings=env.bookings, clock=env.clock).execute(
        customer, payment.id, paid=True
    )
    assert paid.status is PaymentStatus.PAID
    assert env.bookings.bookings["b1"].status is BookingStatus.PAID


@pytest.mark.asyncio
async def test_reconcile_pending_rows(env: _Env) -> None:
    await _seed_pending(env)
    env.gateway.fetch_overrides["order_abc"] = GatewayOrder(
        gateway_order_id="order_abc",
        payment_session_id="session_abc",
        amount_paise=76464,
        status="paid",
    )
    env.clock.advance(timedelta(minutes=6))
    applied = await ReconcilePendingPayments(
        payments=env.payments,
        gateway=env.gateway,
        apply=env.apply,
        clock=env.clock,
    ).execute()
    assert applied == 1
    stored = await env.payments.get("pay1")
    assert stored is not None
    assert stored.status is PaymentStatus.PAID
    assert env.bookings.bookings["b1"].status is BookingStatus.PAID


@pytest.mark.asyncio
async def test_coupon_redeem_once(env: _Env) -> None:
    context = CouponContext(user_id="cust", labor_paise=59900)
    first = await env.coupons.redeem("ONCE", "b1", context)
    assert first.discount_paise == 1000
    again = await env.coupons.redeem("ONCE", "b1", context)
    assert again.discount_paise == 1000
    try:
        await env.coupons.redeem("ONCE", "b2", context)
    except CouponRejected as exc:
        assert "already used" in exc.message.lower()
    else:
        raise AssertionError("second booking must not redeem a one-use coupon")
