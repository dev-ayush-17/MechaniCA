"""In-app notification document stored at users/{userId}/notifications/{id}."""

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class InAppNotification:
    id: str
    user_id: str
    template_id: str
    title: str
    body: str
    deep_link: str
    read_at: datetime | None
    created_at: datetime
