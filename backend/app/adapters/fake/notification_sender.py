from app.domain.notification import OutboundNotification


class RecordingNotifier:
    """Stand-in until M09. Records send() and never throws."""

    def __init__(self) -> None:
        self.sent: list[OutboundNotification] = []

    async def send(self, message: OutboundNotification) -> None:
        self.sent.append(message)
