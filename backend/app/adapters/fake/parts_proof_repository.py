from app.domain.parts_proof import PartsProof


class FakePartsProofRepository:
    """In-memory proofs. There is no delete: FR-MEC-008 forbids mechanic deletes."""

    def __init__(self) -> None:
        self.proofs: dict[str, PartsProof] = {}

    async def save(self, proof: PartsProof) -> PartsProof:
        self.proofs[proof.id] = proof
        return proof

    async def get(self, proof_id: str) -> PartsProof | None:
        return self.proofs.get(proof_id)

    async def list_for_booking(self, booking_id: str) -> list[PartsProof]:
        return [item for item in self.proofs.values() if item.booking_id == booking_id]

    async def list_for_line(self, booking_id: str, line_id: str) -> list[PartsProof]:
        return [
            item
            for item in self.proofs.values()
            if item.booking_id == booking_id and item.line_id == line_id
        ]
