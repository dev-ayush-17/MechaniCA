from typing import Protocol

from app.domain.dispute import Dispute


class DisputeRepository(Protocol):
    """Open, note, and resolve disputes. A second open on one booking conflicts."""

    async def get(self, dispute_id: str) -> Dispute | None: ...

    async def open_for_booking(self, booking_id: str) -> Dispute | None: ...

    async def open(self, dispute: Dispute) -> Dispute: ...

    async def save(self, dispute: Dispute) -> Dispute: ...

    async def list_open(self) -> list[Dispute]: ...
