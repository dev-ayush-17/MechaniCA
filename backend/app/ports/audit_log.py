from typing import Protocol

from app.domain.audit import AuditEvent, AuditTarget


class AuditLog(Protocol):
    async def append(self, event: AuditEvent) -> None: ...

    async def list(self, target: AuditTarget) -> list[AuditEvent]: ...
