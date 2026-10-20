from typing import Protocol

from app.domain.device_token import DeviceToken


class DeviceTokenRepository(Protocol):
    async def upsert(self, token: DeviceToken) -> DeviceToken: ...

    async def list_for_user(self, user_id: str) -> list[DeviceToken]: ...

    async def has_token(self, user_id: str) -> bool: ...
