from datetime import UTC, datetime, timedelta

import pytest

from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.chat_service import FakeChatService
from app.adapters.fake.clock import FakeClock
from app.application.send_message import SendMessage
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.errors import InvalidInput, RateLimited
from app.domain.user import Principal, Role

CUSTOMER = "cust_1"
MECHANIC = "mech_1"
NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)


def _principal(user_id: str = CUSTOMER, role: Role = Role.CUSTOMER) -> Principal:
    return Principal(user_id=user_id, role=role, phone_e164=None)


def _booking(
    *,
    status: BookingStatus = BookingStatus.MECHANIC_ASSIGNED,
    mechanic_id: str | None = MECHANIC,
    updated_at: datetime = NOW,
) -> Booking:
    return Booking(
        id="book_1",
        display_number="MCBOOK001",
        customer_id=CUSTOMER,
        vehicle_id="veh_1",
        service_code="general_service",
        service_name="General Service",
        mode=BookingMode.INSTANT,
        urgency=Urgency.NORMAL,
        status=status,
        payment_method=PaymentMethod.UPI,
        address=AddressSnapshot(
            id="addr_1",
            label="Home",
            line1="Patna",
            city="Patna",
            pincode="800001",
            lat=25.59,
            lng=85.13,
        ),
        labor_paise=59900,
        parts_paise=0,
        fee_paise=4900,
        discount_paise=0,
        cgst_paise=0,
        sgst_paise=0,
        total_paise=64800,
        cancel_fee_paise=0,
        cancel_reason=None,
        scheduled_start=None,
        mechanic_id=mechanic_id,
        lines=(),
        created_at=NOW,
        updated_at=updated_at,
        version=1,
    )


@pytest.fixture
def env() -> tuple[SendMessage, FakeChatService, FakeClock, FakeBookingRepository]:
    bookings = FakeBookingRepository()
    chat = FakeChatService()
    clock = FakeClock(NOW)
    use_case = SendMessage(bookings=bookings, chat=chat, clock=clock)
    return use_case, chat, clock, bookings


@pytest.mark.asyncio
async def test_message_after_24h_is_rejected(
    env: tuple[SendMessage, FakeChatService, FakeClock, FakeBookingRepository],
) -> None:
    use_case, _chat, clock, bookings = env
    paid_at = clock.now() - timedelta(hours=25)
    await bookings.save(
        _booking(status=BookingStatus.PAID, updated_at=paid_at),
    )
    with pytest.raises(InvalidInput, match="closed"):
        await use_case.execute(_principal(), "book_1", text="Hello")


@pytest.mark.asyncio
async def test_twenty_first_message_is_rate_limited(
    env: tuple[SendMessage, FakeChatService, FakeClock, FakeBookingRepository],
) -> None:
    use_case, _chat, _clock, bookings = env
    await bookings.save(_booking())
    for i in range(20):
        await use_case.execute(_principal(), "book_1", text=f"msg {i}")
    with pytest.raises(RateLimited):
        await use_case.execute(_principal(), "book_1", text="one too many")


@pytest.mark.asyncio
async def test_assigned_party_can_send(
    env: tuple[SendMessage, FakeChatService, FakeClock, FakeBookingRepository],
) -> None:
    use_case, chat, _clock, bookings = env
    await bookings.save(_booking())
    sent = await use_case.execute(_principal(), "book_1", text="On the way?")
    assert sent.text == "On the way?"
    assert sent.state.value == "sent"
    listed = await use_case.list(_principal(), "book_1")
    assert [m.id for m in listed] == [sent.id]
    assert len(chat.messages["book_1"]) == 1
