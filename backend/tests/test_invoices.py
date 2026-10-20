from datetime import UTC, datetime

import pytest

from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.file_storage import FakeFileStorage
from app.adapters.fake.invoice_repository import FakeInvoiceRepository
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.payment_repository import FakePaymentRepository
from app.adapters.fake.user_repository import FakeUserRepository
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.adapters.pdf import render_invoice_pdf
from app.application.invoices import DefaultInvoiceService
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingLine,
    BookingMode,
    LineKind,
    LineStatus,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.invoice import format_invoice_number, invoice_period
from app.domain.payment import Payment, PaymentGatewayKind, PaymentReason, PaymentStatus
from app.domain.user import Role, User, UserStatus
from app.domain.vehicle import Vehicle, VehicleType

NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
GSTIN = "22AAAAA0000A1Z5"
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
        status=BookingStatus.PAID,
        payment_method=PaymentMethod.UPI,
        address=ADDR,
        labor_paise=59900,
        parts_paise=25000,
        fee_paise=4900,
        discount_paise=0,
        cgst_paise=8082,
        sgst_paise=8082,
        total_paise=105964,
        cancel_fee_paise=0,
        cancel_reason=None,
        scheduled_start=None,
        mechanic_id="mech",
        lines=(
            BookingLine(
                id="line_oil",
                kind=LineKind.PART,
                name="Engine Oil (1L)",
                amount_paise=25000,
                gst_paise=4500,
                status=LineStatus.APPROVED,
            ),
        ),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )


def _payment() -> Payment:
    return Payment(
        id="pay1",
        booking_id="b1",
        payer_id="cust",
        method=PaymentMethod.UPI,
        amount_paise=105964,
        status=PaymentStatus.PAID,
        gateway=PaymentGatewayKind.CASHFREE,
        gateway_order_id="order_abc",
        payment_session_id="session_abc",
        idempotency_key="11111111-1111-1111-1111-111111111111",
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


class _Env:
    def __init__(self) -> None:
        self.bookings = FakeBookingRepository()
        self.payments = FakePaymentRepository()
        self.users = FakeUserRepository()
        self.vehicles = FakeVehicleRepository()
        self.mechanics = FakeMechanicRepository()
        self.invoices = FakeInvoiceRepository()
        self.storage = FakeFileStorage()
        self.clock = FakeClock(NOW)
        self.service = DefaultInvoiceService(
            invoices=self.invoices,
            storage=self.storage,
            bookings=self.bookings,
            payments=self.payments,
            users=self.users,
            vehicles=self.vehicles,
            mechanics=self.mechanics,
            clock=self.clock,
            gstin=GSTIN,
            render_pdf=render_invoice_pdf,
        )

    async def seed(self) -> None:
        await self.bookings.save(_booking())
        await self.payments.insert(_payment())
        await self.users.upsert(
            User(
                id="cust",
                role=Role.CUSTOMER,
                name="Priya Sharma",
                phone_e164="+919876543210",
                status=UserStatus.ACTIVE,
                auth_provider="fake",
                auth_subject="cust",
                created_at=NOW,
                updated_at=NOW,
            )
        )
        await self.vehicles.save(
            Vehicle(
                id="veh1",
                owner_id="cust",
                vehicle_type=VehicleType.TWO_WHEELER,
                brand="Honda",
                model="Activa",
                year=2022,
                registration_number="BR01AB1234",
                fuel_type="petrol",
                color=None,
                odometer_km=None,
                is_primary=True,
                created_at=NOW,
                updated_at=NOW,
                version=1,
            )
        )
        self.mechanics.seed_online(
            "mech", now=NOW, lat=25.5941, lng=85.1376, radius_km=10.0, display_name="Imran"
        )


@pytest.fixture
def env() -> _Env:
    return _Env()


@pytest.mark.asyncio
async def test_invoice_total_matches_payment(env: _Env) -> None:
    await env.seed()
    invoice = await env.service.render("b1")
    payment = await env.payments.get("pay1")
    assert payment is not None
    assert invoice.total_paise == payment.amount_paise
    assert invoice.number == "MC-202606-000001"
    assert invoice.number == format_invoice_number(invoice_period(NOW), 1)
    names = [line.name for line in invoice.lines]
    assert names == ["General Service", "Convenience fee", "Engine Oil (1L)"]
    line_total = sum(line.amount_paise for line in invoice.lines)
    assert line_total + invoice.cgst_paise + invoice.sgst_paise == payment.amount_paise
    pdf = env.storage.objects[invoice.storage_path][0]
    text = pdf.decode("latin-1")
    assert invoice.number in text
    assert "Priya Sharma" in text
    assert "BR01AB1234" in text
    assert "Imran" in text
    assert GSTIN in text
    assert "Engine Oil" in text
    assert "upi" in text
    assert "b1" in text


@pytest.mark.asyncio
async def test_second_render_keeps_version_one(env: _Env) -> None:
    await env.seed()
    first = await env.service.render("b1")
    stored = env.storage.objects[first.storage_path][0]
    second = await env.service.render("b1")
    assert second.version == 1
    assert first.version == 1
    assert second.number == first.number
    assert second.storage_path == "invoices/b1/v1.pdf"
    assert env.invoices.sequences["202606"] == 1
    assert env.storage.objects[first.storage_path][0] == stored
