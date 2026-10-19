from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.ports.idempotency_store import IdempotencyRecord


def _parse_time(value: object) -> datetime:
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


class FirestoreIdempotencyStore:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self) -> Any:
        return self._db.collection("idempotencyKeys")

    def _doc_id(self, user_id: str, key: str) -> str:
        return f"{user_id}_{key}"

    async def get(self, user_id: str, key: str) -> IdempotencyRecord | None:
        snap = self._col().document(self._doc_id(user_id, key)).get()
        if not snap.exists:
            return None
        data = snap.to_dict() or {}
        return IdempotencyRecord(
            body_hash=str(data["bodyHash"]),
            booking_id=str(data["bookingId"]),
            created_at=_parse_time(data["createdAt"]),
        )

    async def put(self, user_id: str, key: str, record: IdempotencyRecord) -> None:
        self._col().document(self._doc_id(user_id, key)).set(
            {
                "userId": user_id,
                "key": key,
                "bodyHash": record.body_hash,
                "bookingId": record.booking_id,
                "createdAt": record.created_at,
            }
        )
