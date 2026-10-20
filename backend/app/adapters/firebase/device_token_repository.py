import hashlib
from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.domain.device_token import DevicePlatform, DeviceToken


def token_doc_id(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def _parse_time(value: object) -> datetime:
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


class FirestoreDeviceTokenRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self, user_id: str) -> Any:
        return self._db.collection("users").document(user_id).collection("devices")

    async def upsert(self, token: DeviceToken) -> DeviceToken:
        self._col(token.user_id).document(token_doc_id(token.token)).set(
            {
                "token": token.token,
                "platform": token.platform.value,
                "createdAt": token.created_at,
                "updatedAt": token.updated_at,
            }
        )
        return token

    async def list_for_user(self, user_id: str) -> list[DeviceToken]:
        snaps = self._col(user_id).stream()
        items: list[DeviceToken] = []
        for snap in snaps:
            data = snap.to_dict() or {}
            items.append(
                DeviceToken(
                    user_id=user_id,
                    token=str(data["token"]),
                    platform=DevicePlatform(str(data["platform"])),
                    created_at=_parse_time(data["createdAt"]),
                    updated_at=_parse_time(data["updatedAt"]),
                )
            )
        return items

    async def has_token(self, user_id: str) -> bool:
        snaps = self._col(user_id).limit(1).stream()
        return any(True for _ in snaps)
