from collections.abc import Sequence
from typing import Protocol

from app.domain.audit import AuditEvent, AuditTarget


class AuditLog(Protocol):
    async def append(self, event: AuditEvent) -> None: ...

    async def list(self, target: AuditTarget) -> Sequence[AuditEvent]: ...

    async def list_recent(self, *, limit: int = 100) -> Sequence[AuditEvent]: ...
