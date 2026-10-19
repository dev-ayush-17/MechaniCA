from app.domain.audit import AuditEvent, AuditTarget


class FakeAuditLog:
    def __init__(self) -> None:
        self.events: list[AuditEvent] = []

    async def append(self, event: AuditEvent) -> None:
        self.events.append(event)

    async def list(self, target: AuditTarget) -> list[AuditEvent]:
        return [
            e
            for e in self.events
            if e.target_type == target.target_type and e.target_id == target.target_id
        ]
