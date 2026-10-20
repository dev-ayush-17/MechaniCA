from dataclasses import dataclass
from typing import Protocol

from app.domain.notification_templates import Channel


@dataclass(frozen=True)
class OutboundNotification:
    user_id: str
    channel: Channel
    template_id: str
    title: str
    body: str
    data: dict[str, str]
    deep_link: str


class NotificationSender(Protocol):
    """One port for push, in-app, and SMS. Channel lives on the message."""

    async def send(self, message: OutboundNotification) -> None: ...
