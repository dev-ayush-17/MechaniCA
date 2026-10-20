from dataclasses import dataclass

from app.domain.booking import Booking, BookingLine, LineStatus
from app.domain.errors import NotFound
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock


@dataclass(frozen=True)
class ExpireExtraLine:
    """Reject a pending extra line after 10 minutes. Safe to run twice."""

    bookings: BookingRepository
    clock: Clock

    async def execute(self, booking_id: str, line_id: str) -> Booking:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        found = next((line for line in booking.lines if line.id == line_id), None)
        if found is None:
            raise NotFound("We could not find that line.")
        if found.status is not LineStatus.PENDING_APPROVAL:
            return booking
        updated_line = BookingLine(
            id=found.id,
            kind=found.kind,
            name=found.name,
            amount_paise=found.amount_paise,
            gst_paise=found.gst_paise,
            status=LineStatus.REJECTED,
            part_replacement=found.part_replacement,
            created_at=found.created_at,
        )
        lines = tuple(updated_line if line.id == line_id else line for line in booking.lines)
        return await self.bookings.save(booking.with_lines(lines, now=self.clock.now()))
