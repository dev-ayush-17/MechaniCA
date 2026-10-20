from datetime import UTC, datetime, timedelta

import pytest

from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.job_scheduler import FakeJobScheduler
from app.application.expire_extra_line import ExpireExtraLine
from app.application.extra_line import AddExtraLine
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
from app.domain.user import Principal, Role

NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
MECH = Principal(user_id="mech_a", role=Role.MECHANIC, phone_e164="+919811122233")


def _booking() -> Booking:
    labor = BookingLine(
        id="labor_1",
        kind=LineKind.LABOR,
        name="General Service",
        amount_paise=59900,
        gst_paise=0,
        status=LineStatus.INCLUDED,
    )
    return Booking(
        id="book_1",
        display_number="MCBOOK001",
        customer_id="cust_1",
        vehicle_id="veh_1",
        service_code="general_service",
        service_name="General Service",
        mode=BookingMode.INSTANT,
        urgency=Urgency.NORMAL,
        status=BookingStatus.IN_SERVICE,
        payment_method=PaymentMethod.UPI,
        address=AddressSnapshot(
            id="addr_home",
            label="Home",
            line1="Fraser Road",
            city="Patna",
            pincode="800001",
            lat=25.5941,
            lng=85.1376,
        ),
        labor_paise=59900,
        parts_paise=0,
        fee_paise=4900,
        discount_paise=0,
        cgst_paise=5800,
        sgst_paise=5800,
        total_paise=76400,
        cancel_fee_paise=0,
        cancel_reason=None,
        scheduled_start=None,
        mechanic_id="mech_a",
        lines=(labor,),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )


@pytest.mark.asyncio
async def test_extra_work_times_out_after_ten_minutes() -> None:
    clock = FakeClock(NOW)
    bookings = FakeBookingRepository()
    scheduler = FakeJobScheduler()
    await bookings.save(_booking())
    added = await AddExtraLine(
        bookings=bookings, clock=clock, gst_bps=1800, scheduler=scheduler
    ).execute(MECH, "book_1", name="Brake pads", amount_paise=12000)
    pending = next(line for line in added.lines if line.status is LineStatus.PENDING_APPROVAL)
    assert f"extra-line-{pending.id}" in scheduler.jobs
    clock.advance(timedelta(minutes=10))
    timeout = ExpireExtraLine(bookings=bookings, clock=clock)
    first = await timeout.execute("book_1", pending.id)
    second = await timeout.execute("book_1", pending.id)
    statuses = {line.id: line.status for line in first.lines}
    assert statuses[pending.id] is LineStatus.REJECTED
    assert second.lines == first.lines
    assert first.total_paise == 76400
