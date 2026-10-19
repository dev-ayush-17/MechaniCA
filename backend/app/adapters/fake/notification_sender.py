from app.domain.errors import Unavailable
from app.ports.notification_sender import OutboundNotification


class RecordingNotificationSender:
    """Records send() and never raises unless fail=True, for the rollback test."""

    def __init__(self, *, fail: bool = False) -> None:
        self.sent: list[OutboundNotification] = []
        self._fail = fail

    async def send(self, message: OutboundNotification) -> None:
        self.sent.append(message)
        if self._fail:
            raise Unavailable("Push delivery failed.")
