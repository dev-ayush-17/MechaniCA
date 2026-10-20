import json
from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.audit_log import FakeAuditLog
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.coupon_service import FakeCouponService
from app.adapters.fake.file_storage import FakeFileStorage
from app.adapters.fake.invoice_repository import FakeInvoiceRepository
from app.adapters.fake.job_scheduler import FakeJobScheduler
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.notification_sender import RecordingNotifier
from app.adapters.fake.payment_gateway import FakePaymentGateway
from app.adapters.fake.payment_repository import FakePaymentRepository
from app.adapters.fake.user_repository import FakeUserRepository
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.adapters.fake.wallet_service import FakeWalletService
from app.adapters.pdf import render_invoice_pdf
from app.api.deps import (
    apply_gateway_event_dep,
    audit_log_dep,
    auth_verifier_dep,
    booking_repository_dep,
    clock_dep,
    coupon_service_dep,
    create_payment_dep,
    file_storage_dep,
    get_invoice_dep,
    invoice_repository_dep,
    invoice_service_dep,
    job_scheduler_dep,
    mechanic_repository_dep,
    payment_gateway_dep,
    payment_repository_dep,
    role_claims_dep,
    user_repository_dep,
    vehicle_repository_dep,
    wallet_service_dep,
)
from app.application.apply_payment import ApplyGatewayEvent
from app.application.create_payment import CreatePayment
from app.application.invoices import DefaultInvoiceService, GetInvoice
from app.core.config import get_settings
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
OTHER = "cust_other"
PHONE = "+919876543210"
TOKEN = f"fake:{UID}:{PHONE}"
OTHER_TOKEN = f"fake:{OTHER}:+919811111111"
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


def _headers(token: str = TOKEN, key: str = KEY) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}", "Idempotency-Key": key}


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
        self.scheduler = FakeJobScheduler()
        self.storage = FakeFileStorage()
        self.invoices = FakeInvoiceRepository()
        self.users = FakeUserRepository()
        self.vehicles = FakeVehicleRepository()
        self.mechanics = FakeMechanicRepository()
        self.bookings.bookings["b_pay"] = _completed_booking()
        self.mechanics.seed_online(
            "mech", now=NOW, lat=25.5941, lng=85.1376, radius_km=10.0, display_name="Imran"
        )
        service = DefaultInvoiceService(
            invoices=self.invoices,
            storage=self.storage,
            bookings=self.bookings,
            payments=self.payments,
            users=self.users,
            vehicles=self.vehicles,
            mechanics=self.mechanics,
            clock=self.clock,
            gstin=get_settings().gstin,
            render_pdf=render_invoice_pdf,
        )
        create = CreatePayment(
            payments=self.payments,
            bookings=self.bookings,
            gateway=self.gateway,
            wallet=self.wallet,
            coupons=self.coupons,
            clock=self.clock,
            gst_bps=1800,
            scheduler=self.scheduler,
        )
        apply = ApplyGatewayEvent(
            payments=self.payments,
            bookings=self.bookings,
            wallet=self.wallet,
            audit=self.audit,
            notifier=self.notifier,
            clock=self.clock,
            scheduler=self.scheduler,
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
        app.dependency_overrides[job_scheduler_dep] = lambda: self.scheduler
        app.dependency_overrides[file_storage_dep] = lambda: self.storage
        app.dependency_overrides[invoice_repository_dep] = lambda: self.invoices
        app.dependency_overrides[user_repository_dep] = lambda: self.users
        app.dependency_overrides[vehicle_repository_dep] = lambda: self.vehicles
        app.dependency_overrides[mechanic_repository_dep] = lambda: self.mechanics
        app.dependency_overrides[create_payment_dep] = lambda: create
        app.dependency_overrides[apply_gateway_event_dep] = lambda: apply
        app.dependency_overrides[invoice_service_dep] = lambda: service
        app.dependency_overrides[get_invoice_dep] = lambda: GetInvoice(
            invoices=service, bookings=self.bookings, storage=self.storage
        )
        self.client = TestClient(app)

    def run_due_invoice_jobs(self) -> None:
        token = get_settings().internal_job_token
        for job in self.scheduler.due(self.clock.now()):
            if job.target_path != "/v1/internal/invoices/render":
                continue
            response = self.client.post(
                job.target_path,
                json={"bookingId": job.body["bookingId"]},
                headers={"X-Internal-Job-Token": token},
            )
            assert response.status_code == 200


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def _pay_online(env: _Env) -> None:
    created = env.client.post(
        "/v1/payments",
        json={"bookingId": "b_pay", "method": "upi"},
        headers=_headers(),
    )
    assert created.status_code == 201
    order_id = created.json()["cashfree"]["orderId"]
    raw = json.dumps(
        {
            "eventId": "evt_ok",
            "orderId": order_id,
            "amountPaise": 76464,
            "status": "success",
        }
    ).encode()
    paid = env.client.post(
        "/v1/payments/cashfree/webhook",
        content=raw,
        headers=env.gateway.signed_headers(raw),
    )
    assert paid.status_code == 200
    assert created.json()["status"] == "pending"


def test_paid_booking_invoice_url_after_job(env: _Env) -> None:
    _pay_online(env)
    missing = env.client.get("/v1/invoices/b_pay", headers=_headers())
    assert missing.status_code == 404
    assert "invoice-render-b_pay" in env.scheduler.jobs
    env.run_due_invoice_jobs()
    found = env.client.get("/v1/invoices/b_pay", headers=_headers())
    assert found.status_code == 200
    body = found.json()
    assert body["downloadUrl"].startswith("https://storage.fake/download/invoices/b_pay/v1.pdf")
    assert body["totalPaise"] == 76464
    assert body["number"] == "MC-202606-000001"
    assert body["gstin"] == "22AAAAA0000A1Z5"


def test_customer_cannot_read_another_invoice(env: _Env) -> None:
    _pay_online(env)
    env.run_due_invoice_jobs()
    denied = env.client.get("/v1/invoices/b_pay", headers=_headers(token=OTHER_TOKEN))
    assert denied.status_code == 403
    assert denied.json()["error"]["code"] == "permission_denied"
    owner = env.client.get("/v1/invoices/b_pay", headers=_headers())
    assert owner.status_code == 200


def test_wallet_pay_schedules_invoice(env: _Env) -> None:
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
    assert "invoice-render-b_pay" in env.scheduler.jobs
    env.run_due_invoice_jobs()
    found = env.client.get("/v1/invoices/b_pay", headers=_headers())
    assert found.status_code == 200
    assert found.json()["totalPaise"] == 76464


@pytest.mark.asyncio
async def test_cash_confirm_schedules_invoice(env: _Env) -> None:
    from app.application.cash_confirm import ConfirmCash, MarkCashCollected
    from app.domain.payment import Payment, PaymentGatewayKind, PaymentReason, PaymentStatus
    from app.domain.user import Principal

    payment = Payment(
        id="pay_cash",
        booking_id="b_pay",
        payer_id=UID,
        method=PaymentMethod.CASH,
        amount_paise=76464,
        status=PaymentStatus.PENDING,
        gateway=PaymentGatewayKind.CASH,
        gateway_order_id=None,
        payment_session_id=None,
        idempotency_key=KEY,
        reason=PaymentReason.BOOKING,
        refunded_paise=0,
        cash_mechanic_marked_at=None,
        cash_customer_marked_at=None,
        cash_staff_note=None,
        applied_event_ids=(),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )
    await env.payments.insert(payment)
    mechanic = Principal(user_id="mech", role=Role.MECHANIC, phone_e164="+919811111111")
    customer = Principal(user_id=UID, role=Role.CUSTOMER, phone_e164=PHONE)
    await MarkCashCollected(
        payments=env.payments,
        bookings=env.bookings,
        notifier=env.notifier,
        clock=env.clock,
    ).execute(mechanic, payment.id)
    await ConfirmCash(
        payments=env.payments,
        bookings=env.bookings,
        clock=env.clock,
        scheduler=env.scheduler,
    ).execute(customer, payment.id, paid=True)
    assert "invoice-render-b_pay" in env.scheduler.jobs
    env.run_due_invoice_jobs()
    found = env.client.get("/v1/invoices/b_pay", headers=_headers())
    assert found.status_code == 200
