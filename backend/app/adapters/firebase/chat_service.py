from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.domain.chat import ChatMessage, MessageState


def _parse_time(value: object) -> datetime:
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


def _to_doc(message: ChatMessage) -> dict[str, object]:
    return {
        "bookingId": message.booking_id,
        "senderId": message.sender_id,
        "senderRole": message.sender_role,
        "text": message.text,
        "mediaPath": message.media_path,
        "createdAt": message.created_at,
        "state": message.state.value,
    }


def _from_doc(message_id: str, data: dict[str, object]) -> ChatMessage:
    return ChatMessage(
        id=message_id,
        booking_id=str(data["bookingId"]),
        sender_id=str(data["senderId"]),
        sender_role=str(data["senderRole"]),
        text=str(data["text"]) if data.get("text") else None,
        media_path=str(data["mediaPath"]) if data.get("mediaPath") else None,
        created_at=_parse_time(data["createdAt"]),
        state=MessageState(str(data.get("state", "sent"))),
    )


class FirestoreChatService:
    """Admin SDK writer. Client rules deny writes; parties may read."""

    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self, booking_id: str) -> Any:
        return self._db.collection("bookings").document(booking_id).collection("messages")

    async def send(self, message: ChatMessage) -> ChatMessage:
        self._col(message.booking_id).document(message.id).set(_to_doc(message))
        return message

    async def list(self, booking_id: str, after: datetime | None = None) -> list[ChatMessage]:
        query = self._col(booking_id).order_by("createdAt")
        if after is not None:
            query = query.where("createdAt", ">", after)
        return [_from_doc(s.id, s.to_dict() or {}) for s in query.stream()]

    async def get(self, booking_id: str, message_id: str) -> ChatMessage | None:
        snap = self._col(booking_id).document(message_id).get()
        if not snap.exists:
            return None
        return _from_doc(snap.id, snap.to_dict() or {})
