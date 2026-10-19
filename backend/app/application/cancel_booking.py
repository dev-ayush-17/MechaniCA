from dataclasses import dataclass

from app.domain.booking import Booking, BookingPolicy
from app.domain.booking_state import BookingStatus, cancel_fee_paise
from app.domain.errors import NotFound, PermissionDenied
from app.domain.user import Principal, Role
from app.domain.wallet import LedgerDirection, LedgerEntry, LedgerReason
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.wallet_service import WalletService


@dataclass(frozen=True)
class CancelBooking:
    """Customer cancel under the fee table. Records the fee; does not charge a card."""

    bookings: BookingRepository
    clock: Clock
    policy: BookingPolicy
    wallet: WalletService

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
        now = self.clock.now()
        updated = booking.with_status(
            BookingStatus.CANCELLED,
            now=now,
            cancel_fee_paise=fee,
            cancel_reason=reason.strip() or "Cancelled",
        )
        saved = await self.bookings.save(updated)
        if fee > 0:
            await self.wallet.record_debt(
                booking.customer_id,
                LedgerEntry(
                    id=f"cancel_{booking.id}",
                    user_id=booking.customer_id,
                    booking_id=booking.id,
                    direction=LedgerDirection.DEBIT,
                    amount_paise=fee,
                    reason=LedgerReason.CANCEL_FEE,
                    created_at=now,
                ),
            )
        return saved
