"""Chat thread rules. The thread id is the booking id (FR-COM-001, FR-COM-004)."""

from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import StrEnum

from app.domain.booking import Booking
from app.domain.booking_state import BookingStatus

CHAT_WINDOW = timedelta(hours=24)
RATE_LIMIT_COUNT = 20
RATE_LIMIT_WINDOW = timedelta(minutes=10)
TEXT_MIN = 1
TEXT_MAX = 1000

# Chat opens at mechanicAssigned and stays open through in-progress statuses.
_OPEN: frozenset[BookingStatus] = frozenset(
    {
        BookingStatus.MECHANIC_ASSIGNED,
        BookingStatus.EN_ROUTE,
        BookingStatus.ARRIVED,
        BookingStatus.IN_SERVICE,
        BookingStatus.COMPLETED,
        BookingStatus.DISPUTED,
    }
)
_TERMINAL: frozenset[BookingStatus] = frozenset(
    {
        BookingStatus.PAID,
        BookingStatus.CANCELLED,
        BookingStatus.FAILED,
    }
)


class MessageState(StrEnum):
    SENDING = "sending"
    SENT = "sent"
    FAILED = "failed"


@dataclass(frozen=True)
class ChatMessage:
    id: str
    booking_id: str
    sender_id: str
    sender_role: str
    text: str | None
    media_path: str | None
    created_at: datetime
    state: MessageState


def chat_writable(booking: Booking, now: datetime) -> bool:
    """True from mechanicAssigned until 24 hours after a terminal status."""
    if not booking.mechanic_id:
        return False
    if booking.status in _OPEN:
        return True
    if booking.status in _TERMINAL:
        return now < booking.updated_at + CHAT_WINDOW
    return False
