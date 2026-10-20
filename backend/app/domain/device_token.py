"""Registered FCM device token. The raw token is stored for send, never logged."""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class DevicePlatform(StrEnum):
    ANDROID = "android"
    IOS = "ios"
    WEB = "web"


@dataclass(frozen=True)
class DeviceToken:
    user_id: str
    token: str
    platform: DevicePlatform
    created_at: datetime
    updated_at: datetime
