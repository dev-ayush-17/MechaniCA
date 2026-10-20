from datetime import datetime

from app.domain.notification import InAppNotification


class FakeNotificationRepository:
    """In-memory users/{userId}/notifications/{id}."""

    def __init__(self) -> None:
        self.items: dict[tuple[str, str], InAppNotification] = {}

    async def get(self, user_id: str, notification_id: str) -> InAppNotification | None:
        return self.items.get((user_id, notification_id))

    async def list_for_user(self, user_id: str) -> list[InAppNotification]:
        found = [item for (uid, _), item in self.items.items() if uid == user_id]
        found.sort(key=lambda item: item.created_at, reverse=True)
        return found

    async def save(self, item: InAppNotification) -> InAppNotification:
        self.items[(item.user_id, item.id)] = item
        return item

    async def mark_read(
        self, user_id: str, notification_id: str, *, read_at: datetime
    ) -> InAppNotification | None:
        current = self.items.get((user_id, notification_id))
        if current is None:
            return None
        updated = InAppNotification(
            id=current.id,
            user_id=current.user_id,
            template_id=current.template_id,
            title=current.title,
            body=current.body,
            deep_link=current.deep_link,
            read_at=current.read_at or read_at,
            created_at=current.created_at,
        )
        self.items[(user_id, notification_id)] = updated
        return updated

    async def delete(self, user_id: str, notification_id: str) -> bool:
        return self.items.pop((user_id, notification_id), None) is not None
