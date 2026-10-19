from dataclasses import dataclass

from app.application.dispatch import SequentialDispatch
from app.domain.booking_state import BookingStatus
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
        return len(expired) + stale
