from collections.abc import Sequence

from app.domain.audit import AuditEvent, AuditTarget


class FakeAuditLog:
    def __init__(self) -> None:
        self.events: list[AuditEvent] = []

    async def append(self, event: AuditEvent) -> None:
        self.events.append(event)

    async def list(self, target: AuditTarget) -> Sequence[AuditEvent]:
        return [
            e
            for e in self.events
            if e.target_type == target.target_type and e.target_id == target.target_id
        ]

    async def list_recent(self, *, limit: int = 100) -> Sequence[AuditEvent]:
        return list(reversed(self.events[-limit:]))
