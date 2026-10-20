"""FCM adapter for NotificationSender. Vendor SDK stays in this file."""

import asyncio
import uuid

import firebase_admin
from firebase_admin import exceptions as fb_exceptions
from firebase_admin import messaging

from app.domain.errors import Unavailable
from app.domain.notification import InAppNotification
from app.domain.notification_templates import Channel
from app.ports.clock import Clock
from app.ports.device_token_repository import DeviceTokenRepository
from app.ports.notification_repository import NotificationRepository
from app.ports.notification_sender import OutboundNotification


class FcmNotificationSender:
    """Push via FCM, in-app via the notification repository. SMS is not configured."""

    def __init__(
        self,
        project_id: str,
        notifications: NotificationRepository,
        devices: DeviceTokenRepository,
        clock: Clock,
    ) -> None:
        self._notifications = notifications
        self._devices = devices
        self._clock = clock
        try:
            self._app = firebase_admin.get_app()
        except ValueError:
            self._app = firebase_admin.initialize_app(options={"projectId": project_id})

    async def send(self, message: OutboundNotification) -> None:
        if message.channel is Channel.IN_APP:
            await self._notifications.save(
                InAppNotification(
                    id=str(uuid.uuid4()),
                    user_id=message.user_id,
                    template_id=message.template_id,
                    title=message.title,
                    body=message.body,
                    deep_link=message.deep_link,
                    read_at=None,
                    created_at=self._clock.now(),
                )
            )
            return
        if message.channel is Channel.SMS:
            raise Unavailable("SMS is not configured.")
        tokens = [item.token for item in await self._devices.list_for_user(message.user_id)]
        if not tokens:
            return
        try:
            await asyncio.to_thread(self._send_push, tokens, message)
        except (ValueError, fb_exceptions.FirebaseError) as exc:
            raise Unavailable("Push is unavailable. Try again.") from exc

    def _send_push(self, tokens: list[str], message: OutboundNotification) -> None:
        payload = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(title=message.title, body=message.body),
            data={"deepLink": message.deep_link, "templateId": message.template_id},
        )
        messaging.send_each_for_multicast(payload, app=self._app)
