from datetime import datetime
from typing import Protocol

from app.domain.notification import InAppNotification


class NotificationRepository(Protocol):
    """Persists in-app notification documents. FastAPI is the only writer."""

    async def get(self, user_id: str, notification_id: str) -> InAppNotification | None: ...

    async def list_for_user(self, user_id: str) -> list[InAppNotification]: ...

    async def save(self, item: InAppNotification) -> InAppNotification: ...

    async def mark_read(
        self, user_id: str, notification_id: str, *, read_at: datetime
    ) -> InAppNotification | None: ...

    async def delete(self, user_id: str, notification_id: str) -> bool: ...
