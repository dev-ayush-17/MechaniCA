from dataclasses import dataclass

from app.domain.device_token import DevicePlatform, DeviceToken
from app.domain.errors import InvalidInput
from app.domain.user import Principal
from app.ports.clock import Clock
from app.ports.device_token_repository import DeviceTokenRepository


@dataclass(frozen=True)
class RegisterDevice:
    devices: DeviceTokenRepository
    clock: Clock

    async def execute(self, principal: Principal, *, token: str, platform: str) -> DeviceToken:
        cleaned = token.strip()
        if not cleaned:
            raise InvalidInput("Device token is required.", fields={"token": "required"})
        try:
            parsed = DevicePlatform(platform)
        except ValueError as exc:
            raise InvalidInput(
                "Platform must be android, ios, or web.", fields={"platform": "invalid"}
            ) from exc
        now = self.clock.now()
        existing = await self.devices.list_for_user(principal.user_id)
        created_at = now
        for item in existing:
            if item.token == cleaned:
                created_at = item.created_at
                break
        return await self.devices.upsert(
            DeviceToken(
                user_id=principal.user_id,
                token=cleaned,
                platform=parsed,
                created_at=created_at,
                updated_at=now,
            )
        )
