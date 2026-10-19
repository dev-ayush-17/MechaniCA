import uuid

from app.domain.errors import Unavailable
from app.domain.notification import InAppNotification
from app.domain.notification_templates import Channel
from app.ports.clock import Clock
from app.ports.notification_repository import NotificationRepository
from app.ports.notification_sender import OutboundNotification


class RecordingNotificationSender:
    """Records every send. Writes in-app documents. Can fail push for tests."""

    def __init__(self, notifications: NotificationRepository, clock: Clock) -> None:
        self.notifications = notifications
        self.clock = clock
        self.sent: list[OutboundNotification] = []
        self.fail_push_remaining = 0
        self.sms_calls = 0

    async def send(self, message: OutboundNotification) -> None:
        if message.channel is Channel.SMS:
            self.sms_calls += 1
        if message.channel is Channel.PUSH and self.fail_push_remaining > 0:
            self.fail_push_remaining -= 1
            raise Unavailable("Push is unavailable. Try again.")
        self.sent.append(message)
        if message.channel is Channel.IN_APP:
            await self.notifications.save(
                InAppNotification(
                    id=str(uuid.uuid4()),
                    user_id=message.user_id,
                    template_id=message.template_id,
                    title=message.title,
                    body=message.body,
                    deep_link=message.deep_link,
                    read_at=None,
                    created_at=self.clock.now(),
                )
            )
