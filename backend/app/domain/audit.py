from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class AuditEvent:
    id: str
    actor_id: str
    role: str
    action: str
    target_type: str
    target_id: str
    summary: str
    request_id: str
    created_at: datetime


@dataclass(frozen=True)
class AuditTarget:
    target_type: str
    target_id: str
