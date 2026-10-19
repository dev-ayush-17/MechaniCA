from dataclasses import dataclass

from app.domain.booking import Booking, LineStatus
from app.domain.booking_state import BookingStatus, actor_for, assert_transition
from app.domain.errors import InvalidTransition, NotFound, PermissionDenied
from app.domain.parts_proof import REQUIRED_PROOF_KINDS
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.parts_proof_repository import PartsProofRepository


@dataclass(frozen=True)
class TransitionBooking:
    """Apply one legal status change. Clients never write status themselves."""

    bookings: BookingRepository
    clock: Clock
    proofs: PartsProofRepository | None = None

    async def execute(
        self,
        principal: Principal,
        booking_id: str,
        *,
        target: BookingStatus,
        expected_version: int | None = None,
    ) -> Booking:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        self._authorize(principal, booking, target)
        if expected_version is not None and booking.version != expected_version:
            raise InvalidTransition("This booking changed. Refresh and try again.")
        assert_transition(booking.status, target, actor_for(principal.role))
        if target is BookingStatus.COMPLETED:
            await self._assert_parts_photos(booking)
        mechanic_id = booking.mechanic_id
        if principal.role == Role.MECHANIC:
            mechanic_id = principal.user_id
        if target is BookingStatus.CONFIRMED:
            mechanic_id = None
        updated = booking.with_status(target, now=self.clock.now(), mechanic_id=mechanic_id)
        return await self.bookings.save(updated)

    async def _assert_parts_photos(self, booking: Booking) -> None:
        required = [
            line
            for line in booking.lines
            if line.part_replacement and line.status in {LineStatus.INCLUDED, LineStatus.APPROVED}
        ]
        if not required:
            return
        if self.proofs is None:
            raise InvalidTransition("Upload before, after, and old-part photos before completing.")
        for line in required:
            stored = await self.proofs.list_for_line(booking.id, line.id)
            kinds = {item.kind for item in stored if not item.hidden}
            if not REQUIRED_PROOF_KINDS.issubset(kinds):
                raise InvalidTransition(
                    "Upload before, after, and old-part photos before completing."
                )

    def _authorize(self, principal: Principal, booking: Booking, target: BookingStatus) -> None:
        if principal.role in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}:
            return
        if principal.role == Role.CUSTOMER:
            if booking.customer_id != principal.user_id:
                raise PermissionDenied("You do not have access to that booking.")
            return
        if principal.role == Role.MECHANIC:
            if booking.mechanic_id not in {None, principal.user_id}:
                raise PermissionDenied("You are not assigned to this booking.")
            return
        raise PermissionDenied("You cannot change this booking.")
