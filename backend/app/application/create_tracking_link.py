import secrets
from dataclasses import dataclass

from app.domain.booking_state import BookingStatus
from app.domain.errors import NotFound, PermissionDenied
from app.domain.tracking import TRACKING_LINK_TTL, TrackingLink
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.tracking_link_store import TrackingLinkStore

_ENDED = frozenset({BookingStatus.PAID, BookingStatus.CANCELLED, BookingStatus.FAILED})


@dataclass(frozen=True)
class CreateTrackingLink:
    bookings: BookingRepository
    links: TrackingLinkStore
    clock: Clock

    async def execute(self, principal: Principal, booking_id: str) -> TrackingLink:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Only the customer can share tracking.")
        booking = await self.bookings.get(booking_id)
        if booking is None or booking.customer_id != principal.user_id:
            raise NotFound("We could not find that booking.")
        if booking.status in _ENDED:
            raise NotFound("This tracking link has ended.")
        now = self.clock.now()
        return await self.links.save(
            TrackingLink(
                token=secrets.token_urlsafe(24),
                booking_id=booking.id,
                customer_id=booking.customer_id,
                created_at=now,
                expires_at=now + TRACKING_LINK_TTL,
            )
        )
