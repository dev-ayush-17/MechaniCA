"""Look up the chapter 17 matrix and send once per channel."""

from dataclasses import dataclass

from app.core.logging import log_info
from app.domain.errors import Unavailable
from app.domain.notification_templates import (
    SMS_EVENTS,
    Channel,
    Recipient,
    lookup_template,
    render_template,
)
from app.ports.device_token_repository import DeviceTokenRepository
from app.ports.notification_sender import NotificationSender, OutboundNotification


@dataclass(frozen=True)
class Notify:
    sender: NotificationSender
    devices: DeviceTokenRepository
    sms_enabled: bool = False

    async def emit(
        self,
        event_id: str,
        user_id: str,
        data: dict[str, str],
        *,
        recipient: Recipient,
    ) -> None:
        template = lookup_template(event_id, recipient)
        title, body, deep_link = render_template(template, data)
        has_token = await self.devices.has_token(user_id)
        for channel in template.channels:
            if channel is Channel.SMS:
                if not self.sms_enabled or has_token or event_id not in SMS_EVENTS:
                    continue
            message = OutboundNotification(
                user_id=user_id,
                channel=channel,
                template_id=template.event_id,
                title=title,
                body=body,
                data=data,
                deep_link=deep_link,
            )
            if channel is Channel.PUSH:
                await self._send_push(message)
            else:
                await self.sender.send(message)
                _audit(message, success=True)

    async def _send_push(self, message: OutboundNotification) -> None:
        try:
            await self.sender.send(message)
            _audit(message, success=True)
            return
        except Unavailable:
            pass
        try:
            await self.sender.send(message)
            _audit(message, success=True)
        except Unavailable:
            _audit(message, success=False)


def _audit(message: OutboundNotification, *, success: bool) -> None:
    log_info(
        "notification sent",
        template_id=message.template_id,
        user_id=message.user_id,
        channel=message.channel.value,
        success=success,
    )


async def notify_payment_paid(
    notify: Notify,
    *,
    customer_id: str,
    mechanic_id: str | None,
    data: dict[str, str],
) -> None:
    """M10 calls this after payment lands. Safe to unit-test with a direct call."""
    await notify.emit("paymentPaid", customer_id, data, recipient=Recipient.CUSTOMER)
    if mechanic_id:
        await notify.emit("paymentPaid", mechanic_id, data, recipient=Recipient.MECHANIC)


async def notify_payment_failed(notify: Notify, *, customer_id: str, data: dict[str, str]) -> None:
    await notify.emit("paymentFailed", customer_id, data, recipient=Recipient.CUSTOMER)


async def notify_verification_approved(
    notify: Notify, *, mechanic_id: str, data: dict[str, str]
) -> None:
    """M04/M15 call this after an admin approve. Safe to unit-test with a direct call."""
    await notify.emit("verificationApproved", mechanic_id, data, recipient=Recipient.MECHANIC)


async def notify_verification_rejected(
    notify: Notify, *, mechanic_id: str, data: dict[str, str]
) -> None:
    await notify.emit("verificationRejected", mechanic_id, data, recipient=Recipient.MECHANIC)
