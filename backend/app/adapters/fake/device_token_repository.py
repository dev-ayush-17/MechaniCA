from app.domain.device_token import DeviceToken


class FakeDeviceTokenRepository:
    """In-memory device tokens keyed by (user_id, token)."""

    def __init__(self) -> None:
        self.tokens: dict[tuple[str, str], DeviceToken] = {}

    async def upsert(self, token: DeviceToken) -> DeviceToken:
        self.tokens[(token.user_id, token.token)] = token
        return token

    async def list_for_user(self, user_id: str) -> list[DeviceToken]:
        return [item for (uid, _), item in self.tokens.items() if uid == user_id]

    async def has_token(self, user_id: str) -> bool:
        return any(uid == user_id for uid, _ in self.tokens)
