from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.domain.notification import InAppNotification


def _parse_time(value: object) -> datetime:
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


def _to_doc(item: InAppNotification) -> dict[str, object]:
    return {
        "templateId": item.template_id,
        "title": item.title,
        "body": item.body,
        "deepLink": item.deep_link,
        "readAt": item.read_at,
        "createdAt": item.created_at,
    }


def _from_doc(user_id: str, notification_id: str, data: dict[str, object]) -> InAppNotification:
    read_at = data.get("readAt")
    return InAppNotification(
        id=notification_id,
        user_id=user_id,
        template_id=str(data["templateId"]),
        title=str(data["title"]),
        body=str(data["body"]),
        deep_link=str(data["deepLink"]),
        read_at=_parse_time(read_at) if read_at is not None else None,
        created_at=_parse_time(data["createdAt"]),
    )


class FirestoreNotificationRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self, user_id: str) -> Any:
        return self._db.collection("users").document(user_id).collection("notifications")

    async def get(self, user_id: str, notification_id: str) -> InAppNotification | None:
        snap = self._col(user_id).document(notification_id).get()
        if not snap.exists:
            return None
        return _from_doc(user_id, snap.id, snap.to_dict() or {})

    async def list_for_user(self, user_id: str) -> list[InAppNotification]:
        query = self._col(user_id).order_by("createdAt", direction=firestore.Query.DESCENDING)
        return [_from_doc(user_id, snap.id, snap.to_dict() or {}) for snap in query.stream()]

    async def save(self, item: InAppNotification) -> InAppNotification:
        self._col(item.user_id).document(item.id).set(_to_doc(item))
        return item

    async def mark_read(
        self, user_id: str, notification_id: str, *, read_at: datetime
    ) -> InAppNotification | None:
        current = await self.get(user_id, notification_id)
        if current is None:
            return None
        if current.read_at is not None:
            return current
        updated = InAppNotification(
            id=current.id,
            user_id=current.user_id,
            template_id=current.template_id,
            title=current.title,
            body=current.body,
            deep_link=current.deep_link,
            read_at=read_at,
            created_at=current.created_at,
        )
        self._col(user_id).document(notification_id).update({"readAt": read_at})
        return updated

    async def delete(self, user_id: str, notification_id: str) -> bool:
        current = await self.get(user_id, notification_id)
        if current is None:
            return False
        self._col(user_id).document(notification_id).delete()
        return True
