"""Outbound notification shape. M09 owns the real sender; M10 records sends."""

from dataclasses import dataclass
from enum import StrEnum


class NotificationChannel(StrEnum):
    PUSH = "push"
    IN_APP = "inApp"
    SMS = "sms"


@dataclass(frozen=True)
class OutboundNotification:
    user_id: str
    channel: NotificationChannel
    template_id: str
    data: dict[str, str]
    deep_link: str
