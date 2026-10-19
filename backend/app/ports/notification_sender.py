from typing import Protocol

from app.domain.notification import OutboundNotification


class NotificationSender(Protocol):
    """M09 owns the real adapter. M10 binds a recorder that never throws."""

    async def send(self, message: OutboundNotification) -> None: ...
