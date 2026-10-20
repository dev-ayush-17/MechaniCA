from dataclasses import dataclass

from app.application.notify import Notify
from app.domain.booking import Booking, BookingPolicy
from app.domain.booking_state import BookingStatus, cancel_fee_paise
from app.domain.errors import NotFound, PermissionDenied
from app.domain.notification_templates import Recipient
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock


@dataclass(frozen=True)
class CancelBooking:
    """Customer cancel under the fee table. Records the fee; does not charge a card."""

    bookings: BookingRepository
    clock: Clock
    policy: BookingPolicy
    notify: Notify | None = None

    async def execute(self, principal: Principal, booking_id: str, *, reason: str) -> Booking:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        if principal.role == Role.CUSTOMER and booking.customer_id != principal.user_id:
            raise PermissionDenied("You do not have access to that booking.")
        if principal.role not in {Role.CUSTOMER, Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN}:
            raise PermissionDenied("You cannot cancel this booking.")
        fee = cancel_fee_paise(
            booking.status, enroute_fee_paise=self.policy.cancel_fee_enroute_paise
        )
        updated = booking.with_status(
            BookingStatus.CANCELLED,
            now=self.clock.now(),
            cancel_fee_paise=fee,
            cancel_reason=reason.strip() or "Cancelled",
        )
        saved = await self.bookings.save(updated)
        await self._emit(principal, saved)
        return saved

    async def _emit(self, principal: Principal, booking: Booking) -> None:
        if self.notify is None:
            return
        data = {
            "bookingId": booking.id,
            "displayNumber": booking.display_number,
            "serviceName": booking.service_name,
        }
        other_ids: list[str] = []
        if principal.user_id != booking.customer_id:
            other_ids.append(booking.customer_id)
        if booking.mechanic_id and principal.user_id != booking.mechanic_id:
            other_ids.append(booking.mechanic_id)
        for user_id in other_ids:
            await self.notify.emit("bookingCancelled", user_id, data, recipient=Recipient.OTHER)
