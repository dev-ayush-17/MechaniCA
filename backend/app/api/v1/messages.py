import uuid
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Header
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

from app.api.deps import principal_dep, send_message_dep, sign_chat_media_dep
from app.api.errors import error_responses
from app.application.send_message import SendMessage
from app.application.sign_chat_media import SignChatMedia
from app.domain.chat import ChatMessage
from app.domain.errors import IdempotencyKeyRequired, InvalidInput
from app.domain.user import Principal

router = APIRouter(
    prefix="/v1/bookings",
    tags=["messages"],
    responses=error_responses(400, 401, 403, 404, 429),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class SendMessageRequest(_Camel):
    text: str | None = None
    media_path: str | None = None


class ChatMessageOut(_Camel):
    id: str
    booking_id: str
    sender_id: str
    sender_role: str
    text: str | None
    media_path: str | None
    created_at: datetime
    state: str

    @classmethod
    def of(cls, message: ChatMessage) -> "ChatMessageOut":
        return cls(
            id=message.id,
            booking_id=message.booking_id,
            sender_id=message.sender_id,
            sender_role=message.sender_role,
            text=message.text,
            media_path=message.media_path,
            created_at=message.created_at,
            state=message.state.value,
        )


class ChatMessageListOut(_Camel):
    items: list[ChatMessageOut]


class SignChatMediaRequest(_Camel):
    content_type: str
    max_bytes: int = Field(le=5 * 1024 * 1024)


class SignChatMediaOut(_Camel):
    upload_url: str
    path: str
    headers: dict[str, str]


@router.post("/{booking_id}/messages", response_model=ChatMessageOut, status_code=201)
async def send_message(
    booking_id: str,
    body: SendMessageRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[SendMessage, Depends(send_message_dep)],
    idempotency_key: Annotated[str | None, Header()] = None,
) -> ChatMessageOut:
    key = _message_key(idempotency_key)
    message = await use_case.execute(
        principal,
        booking_id,
        text=body.text,
        media_path=body.media_path,
        idempotency_key=key,
    )
    return ChatMessageOut.of(message)


@router.get("/{booking_id}/messages", response_model=ChatMessageListOut)
async def list_messages(
    booking_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[SendMessage, Depends(send_message_dep)],
    after: datetime | None = None,
) -> ChatMessageListOut:
    items = await use_case.list(principal, booking_id, after=after)
    return ChatMessageListOut(items=[ChatMessageOut.of(m) for m in items])


@router.post(
    "/{booking_id}/messages/uploads",
    response_model=SignChatMediaOut,
    status_code=201,
)
async def sign_chat_media(
    booking_id: str,
    body: SignChatMediaRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[SignChatMedia, Depends(sign_chat_media_dep)],
) -> SignChatMediaOut:
    signed = await use_case.execute(
        principal,
        booking_id,
        content_type=body.content_type,
        max_bytes=body.max_bytes,
    )
    return SignChatMediaOut(upload_url=signed.upload_url, path=signed.path, headers=signed.headers)


def _message_key(raw: str | None) -> str:
    if raw is None or not raw.strip():
        raise IdempotencyKeyRequired("Idempotency-Key is required to send a message.")
    try:
        return str(uuid.UUID(raw.strip()))
    except ValueError as exc:
        raise InvalidInput("Idempotency-Key must be a UUID.") from exc
