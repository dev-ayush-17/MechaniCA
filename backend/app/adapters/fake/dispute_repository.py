from app.domain.dispute import Dispute, DisputeStatus
from app.domain.errors import Conflict


class FakeDisputeRepository:
    def __init__(self) -> None:
        self.disputes: dict[str, Dispute] = {}

    async def get(self, dispute_id: str) -> Dispute | None:
        return self.disputes.get(dispute_id)

    async def open_for_booking(self, booking_id: str) -> Dispute | None:
        for dispute in self.disputes.values():
            if dispute.booking_id == booking_id and dispute.status is DisputeStatus.OPEN:
                return dispute
        return None

    async def open(self, dispute: Dispute) -> Dispute:
        existing = await self.open_for_booking(dispute.booking_id)
        if existing is not None:
            raise Conflict("A dispute is already open for this booking.")
        self.disputes[dispute.id] = dispute
        return dispute

    async def save(self, dispute: Dispute) -> Dispute:
        self.disputes[dispute.id] = dispute
        return dispute

    async def list_open(self) -> list[Dispute]:
        return [d for d in self.disputes.values() if d.status is DisputeStatus.OPEN]
