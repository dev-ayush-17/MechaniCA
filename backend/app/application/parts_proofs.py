from dataclasses import dataclass, replace

from app.domain.booking import Booking
from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.parts_proof import PartsProof, ProofKind, proof_storage_path
from app.domain.storage import SignedUpload
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.file_storage import FileStorage
from app.ports.parts_proof_repository import PartsProofRepository

_PROOF_MAX_BYTES = 1_500_000
_PROOF_CONTENT_TYPE = "image/jpeg"


@dataclass(frozen=True)
class CreatePartsProof:
    """Create the proof row and a signed upload. The client never chooses the path."""

    bookings: BookingRepository
    proofs: PartsProofRepository
    storage: FileStorage
    clock: Clock

    async def execute(
        self,
        principal: Principal,
        booking_id: str,
        line_id: str,
        *,
        kind: ProofKind,
    ) -> tuple[PartsProof, SignedUpload]:
        if principal.role != Role.MECHANIC:
            raise PermissionDenied("Mechanic account required.")
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        if booking.mechanic_id not in {None, principal.user_id}:
            raise PermissionDenied("You are not assigned to this booking.")
        line = next((item for item in booking.lines if item.id == line_id), None)
        if line is None:
            raise NotFound("We could not find that line.")
        if not line.part_replacement:
            raise InvalidInput("This line does not need parts photos.")
        path = proof_storage_path(booking.id, line.id, kind)
        proof = PartsProof.create(
            booking_id=booking.id,
            line_id=line.id,
            kind=kind,
            storage_path=path,
            captured_at=self.clock.now(),
        )
        saved = await self.proofs.save(proof)
        signed = await self.storage.signed_upload(path, _PROOF_CONTENT_TYPE, _PROOF_MAX_BYTES)
        return saved, signed


@dataclass(frozen=True)
class ListPartsProofs:
    bookings: BookingRepository
    proofs: PartsProofRepository

    async def execute(self, principal: Principal, booking_id: str) -> list[PartsProof]:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        self._authorize(principal, booking)
        items = await self.proofs.list_for_booking(booking_id)
        if principal.role == Role.CUSTOMER:
            return [item for item in items if not item.hidden]
        return items

    def _authorize(self, principal: Principal, booking: Booking) -> None:
        if principal.role in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}:
            return
        if principal.role == Role.CUSTOMER and booking.customer_id == principal.user_id:
            return
        if principal.role == Role.MECHANIC and booking.mechanic_id in {
            None,
            principal.user_id,
        }:
            return
        raise PermissionDenied("You do not have access to that booking.")


@dataclass(frozen=True)
class HidePartsProof:
    bookings: BookingRepository
    proofs: PartsProofRepository

    async def execute(self, principal: Principal, booking_id: str, proof_id: str) -> PartsProof:
        if principal.role not in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}:
            raise PermissionDenied("Staff access required.")
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        proof = await self.proofs.get(proof_id)
        if proof is None or proof.booking_id != booking_id:
            raise NotFound("We could not find that photo.")
        return await self.proofs.save(replace(proof, hidden=True))
