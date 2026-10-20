from dataclasses import dataclass

from app.domain.errors import NotFound, Unavailable
from app.domain.telephony import MaskedCall
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.telephony import TelephonyPort


@dataclass(frozen=True)
class MaskCall:
    bookings: BookingRepository
    telephony: TelephonyPort
    enabled: bool

    async def execute(self, principal: Principal, booking_id: str) -> MaskedCall:
        if not self.enabled:
            raise Unavailable("Calling is unavailable. Use chat.")
        booking = await self.bookings.get(booking_id)
        if booking is None or not booking.mechanic_id:
            raise NotFound("We could not find that booking.")
        is_party = principal.user_id in {booking.customer_id, booking.mechanic_id}
        is_staff = principal.role in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}
        if not is_party and not is_staff:
            raise NotFound("We could not find that booking.")
        # Party ids, never phones, so a buggy adapter still cannot echo a mobile.
        return await self.telephony.mask(booking.id, booking.customer_id, booking.mechanic_id)
