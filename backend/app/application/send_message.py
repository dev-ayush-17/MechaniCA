import uuid
from dataclasses import dataclass
from datetime import datetime

from app.domain.chat import (
    RATE_LIMIT_COUNT,
    RATE_LIMIT_WINDOW,
    TEXT_MAX,
    TEXT_MIN,
    ChatMessage,
    MessageState,
    chat_writable,
)
from app.domain.errors import InvalidInput, NotFound, RateLimited
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.chat_service import ChatService
from app.ports.clock import Clock


@dataclass(frozen=True)
class SendMessage:
    bookings: BookingRepository
    chat: ChatService
    clock: Clock

    async def execute(
        self,
        principal: Principal,
        booking_id: str,
        *,
        text: str | None,
        media_path: str | None = None,
        idempotency_key: str | None = None,
    ) -> ChatMessage:
        booking = await self.bookings.get(booking_id)
        if booking is None or not _is_party(principal, booking.customer_id, booking.mechanic_id):
            raise NotFound("We could not find that booking.")
        now = self.clock.now()
        if not chat_writable(booking, now):
            raise InvalidInput("This chat is closed.")
        body = (text or "").strip()
        path = (media_path or "").strip() or None
        if path and not path.startswith(f"chat/{booking_id}/"):
            raise InvalidInput("That media path is not allowed.", fields={"mediaPath": "invalid"})
        if path and ".." in path:
            raise InvalidInput("That media path is not allowed.", fields={"mediaPath": "invalid"})
        if not body and not path:
            raise InvalidInput("Enter a message.", fields={"text": "required"})
        if body and (len(body) < TEXT_MIN or len(body) > TEXT_MAX):
            raise InvalidInput(
                "Text must be 1 to 1000 characters.",
                fields={"text": "invalid"},
            )

        if idempotency_key:
            existing = await self.chat.get(booking_id, idempotency_key)
            if existing is not None:
                return existing

        recent = await self.chat.list(booking_id, after=now - RATE_LIMIT_WINDOW)
        if len(recent) >= RATE_LIMIT_COUNT:
            raise RateLimited("Too many messages. Wait a moment.", retry_after_seconds=60)

        message_id = idempotency_key or str(uuid.uuid4())
        message = ChatMessage(
            id=message_id,
            booking_id=booking_id,
            sender_id=principal.user_id,
            sender_role=principal.role.value,
            text=body or None,
            media_path=path,
            created_at=now,
            state=MessageState.SENT,
        )
        return await self.chat.send(message)

    async def list(
        self,
        principal: Principal,
        booking_id: str,
        after: datetime | None = None,
    ) -> list[ChatMessage]:
        booking = await self.bookings.get(booking_id)
        if booking is None or not _is_party(principal, booking.customer_id, booking.mechanic_id):
            raise NotFound("We could not find that booking.")
        return await self.chat.list(booking_id, after=after)


def _is_party(principal: Principal, customer_id: str, mechanic_id: str | None) -> bool:
    if principal.role in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}:
        return True
    if principal.user_id == customer_id:
        return True
    return mechanic_id is not None and principal.user_id == mechanic_id
