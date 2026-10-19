from datetime import datetime
from typing import Protocol

from app.domain.mechanic import Mechanic, MechanicDocument


class MechanicRepository(Protocol):
    async def get(self, mechanic_id: str) -> Mechanic | None: ...

    async def save_profile(self, mechanic: Mechanic) -> Mechanic: ...

    async def set_verification(
        self,
        mechanic_id: str,
        *,
        status: str,
        verified: bool,
        reason: str | None,
        expected_version: int,
    ) -> Mechanic: ...

    async def set_availability(self, mechanic_id: str, *, online: bool) -> Mechanic: ...

    async def record_heartbeat(self, mechanic_id: str, *, at: datetime) -> Mechanic: ...

    async def save_document(self, document: MechanicDocument) -> MechanicDocument: ...

    async def list_documents(self, mechanic_id: str) -> list[MechanicDocument]: ...
