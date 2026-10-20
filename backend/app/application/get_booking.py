from dataclasses import dataclass

from app.domain.booking import Booking
from app.domain.errors import NotFound
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository


@dataclass(frozen=True)
class GetBooking:
    bookings: BookingRepository

    async def execute(self, principal: Principal, booking_id: str) -> Booking:
        booking = await self.bookings.get(booking_id)
        if booking is None or not _may_read(principal, booking):
            raise NotFound("We could not find that booking.")
        return booking

    async def list_mine(self, principal: Principal) -> list[Booking]:
        if principal.role == Role.MECHANIC:
            items = await self.bookings.list_by_mechanic(principal.user_id)
            return sorted(items, key=lambda b: b.created_at, reverse=True)
        if principal.role != Role.CUSTOMER:
            return []
        items = await self.bookings.list_by_customer(principal.user_id)
        return sorted(items, key=lambda b: b.created_at, reverse=True)


def _may_read(principal: Principal, booking: Booking) -> bool:
    if principal.role in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}:
        return True
    if principal.role == Role.CUSTOMER:
        return booking.customer_id == principal.user_id
    if principal.role == Role.MECHANIC:
        return booking.mechanic_id == principal.user_id
    return False
