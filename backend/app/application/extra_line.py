import uuid
from dataclasses import dataclass

from app.domain.booking import Booking, BookingLine, LineKind, LineStatus
from app.domain.booking_state import BookingStatus
from app.domain.catalog import BPS_DENOMINATOR
from app.domain.errors import InvalidInput, InvalidTransition, NotFound, PermissionDenied
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock


@dataclass(frozen=True)
class AddExtraLine:
    """Mechanic adds a pending extra line. The 10-minute timeout is M07."""

    bookings: BookingRepository
    clock: Clock
    gst_bps: int

    async def execute(
        self,
        principal: Principal,
        booking_id: str,
        *,
        name: str,
        amount_paise: int,
        kind: LineKind = LineKind.PART,
    ) -> Booking:
        if principal.role != Role.MECHANIC:
            raise PermissionDenied("Mechanic account required.")
        if amount_paise <= 0:
            raise InvalidInput("Amount must be greater than zero.")
        label = name.strip()
        if not label:
            raise InvalidInput("Name the extra item.")
        booking = await self._load(booking_id)
        if booking.status is not BookingStatus.IN_SERVICE:
            raise InvalidTransition(
                "Extra work can only be added while the service is in progress."
            )
        if booking.mechanic_id not in {None, principal.user_id}:
            raise PermissionDenied("You are not assigned to this booking.")
        gst = amount_paise * self.gst_bps // BPS_DENOMINATOR
        line = BookingLine(
            id=str(uuid.uuid4()),
            kind=kind,
            name=label,
            amount_paise=amount_paise,
            gst_paise=gst,
            status=LineStatus.PENDING_APPROVAL,
            part_replacement=kind is LineKind.PART,
        )
        updated = booking.with_lines((*booking.lines, line), now=self.clock.now())
        return await self.bookings.save(updated)

    async def _load(self, booking_id: str) -> Booking:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        return booking


@dataclass(frozen=True)
class DecideExtraLine:
    """Customer approves or rejects a pending extra line."""

    bookings: BookingRepository
    clock: Clock

    async def execute(
        self,
        principal: Principal,
        booking_id: str,
        line_id: str,
        *,
        approve: bool,
    ) -> Booking:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        if booking.customer_id != principal.user_id:
            raise PermissionDenied("You do not have access to that booking.")
        found = next((line for line in booking.lines if line.id == line_id), None)
        if found is None:
            raise NotFound("We could not find that line.")
        if found.status is not LineStatus.PENDING_APPROVAL:
            raise InvalidTransition("This extra item was already decided.")
        updated_line = BookingLine(
            id=found.id,
            kind=found.kind,
            name=found.name,
            amount_paise=found.amount_paise,
            gst_paise=found.gst_paise,
            status=LineStatus.APPROVED if approve else LineStatus.REJECTED,
            part_replacement=found.part_replacement,
        )
        lines = tuple(updated_line if line.id == line_id else line for line in booking.lines)
        changed = booking.with_lines(lines, now=self.clock.now())
        if approve:
            from dataclasses import replace

            changed = replace(
                changed,
                parts_paise=changed.parts_paise + found.amount_paise,
                total_paise=changed.total_paise + found.amount_paise + found.gst_paise,
            )
        return await self.bookings.save(changed)
