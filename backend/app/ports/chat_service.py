from datetime import datetime
from typing import Protocol

from app.domain.chat import ChatMessage


class ChatService(Protocol):
    """API is the writer. Clients read via list or a Firestore listener."""

    async def send(self, message: ChatMessage) -> ChatMessage: ...

    async def list(
        self, booking_id: str, after: datetime | None = None
    ) -> list[ChatMessage]: ...

    async def get(self, booking_id: str, message_id: str) -> ChatMessage | None: ...
