from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class OutboundNotification:
    user_id: str
    channel: str
    template_id: str
    data: dict[str, str]
    deep_link: str


class NotificationSender(Protocol):
    """M09 owns the real FCM adapter. M07 binds a recording fake."""

    async def send(self, message: OutboundNotification) -> None: ...
