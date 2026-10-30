from dataclasses import dataclass

from app.application.dispatch import SequentialDispatch
from app.application.expire_extra_line import ExpireExtraLine
from app.domain.booking import LineStatus
from app.domain.booking_state import BookingStatus
from app.domain.dispatch import DispatchConfig
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.mechanic_repository import MechanicRepository
from app.ports.offer_repository import OfferRepository


@dataclass(frozen=True)
class SweepExpiredOffers:
    """Safety net when a Cloud Task never fired (ADR-008). Idempotent."""

    offers: OfferRepository
    bookings: BookingRepository
    mechanics: MechanicRepository
    dispatch: SequentialDispatch
    clock: Clock
    extra_lines: ExpireExtraLine | None = None

    async def execute(self) -> int:
        now = self.clock.now()
        expired = await self.offers.list_expired_open(now)
        for offer in expired:
            await self.dispatch.expire(offer.id)
        stale = 0
        assigned = await self.bookings.list_by_status(BookingStatus.MECHANIC_ASSIGNED)
        for booking in assigned:
            if booking.mechanic_id is None:
                continue
            mechanic = await self.mechanics.get(booking.mechanic_id)
            beat = None if mechanic is None else mechanic.last_heartbeat_at
            if beat is None:
                continue
            age = (now - beat).total_seconds()
            if age < self.dispatch.config.assigned_stale_seconds:
                continue
            cleared = booking.with_status(BookingStatus.CONFIRMED, now=now)
            await self.bookings.save(cleared)
            await self.dispatch.offer(booking.id)
            stale += 1
        extra = 0
        if self.extra_lines is not None:
            timeout = DispatchConfig().extra_work_timeout_seconds
            in_service = await self.bookings.list_by_status(BookingStatus.IN_SERVICE)
            for booking in in_service:
                for line in booking.lines:
                    if line.status is not LineStatus.PENDING_APPROVAL:
                        continue
                    if line.created_at is None:
                        continue
                    if (now - line.created_at).total_seconds() < timeout:
                        continue
                    await self.extra_lines.execute(booking.id, line.id)
                    extra += 1
        confirmed = await self.bookings.list_by_status(BookingStatus.CONFIRMED)
        for booking in confirmed:
            # Idempotent: an open offer is returned, a scheduled job not yet due
            # is skipped, and an empty candidate list fails only after the wait.
            await self.dispatch.offer(booking.id)
        return len(expired) + stale + extra + len(confirmed)
