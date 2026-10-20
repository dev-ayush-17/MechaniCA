from typing import Protocol

from app.domain.parts_proof import PartsProof


class PartsProofRepository(Protocol):
    """Proof uploads fail differently from booking writes, so they are not on BookingRepository."""

    async def save(self, proof: PartsProof) -> PartsProof: ...

    async def get(self, proof_id: str) -> PartsProof | None: ...

    async def list_for_booking(self, booking_id: str) -> list[PartsProof]: ...

    async def list_for_line(self, booking_id: str, line_id: str) -> list[PartsProof]: ...
