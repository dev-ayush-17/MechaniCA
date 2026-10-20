from datetime import datetime

from app.domain.chat import ChatMessage


class FakeChatService:
    """In-memory messages keyed by booking id. Tests and the demo bind this."""

    def __init__(self) -> None:
        self.messages: dict[str, dict[str, ChatMessage]] = {}

    async def send(self, message: ChatMessage) -> ChatMessage:
        bucket = self.messages.setdefault(message.booking_id, {})
        bucket[message.id] = message
        return message

    async def list(self, booking_id: str, after: datetime | None = None) -> list[ChatMessage]:
        items = list(self.messages.get(booking_id, {}).values())
        if after is not None:
            items = [m for m in items if m.created_at > after]
        return sorted(items, key=lambda m: m.created_at)

    async def get(self, booking_id: str, message_id: str) -> ChatMessage | None:
        return self.messages.get(booking_id, {}).get(message_id)
