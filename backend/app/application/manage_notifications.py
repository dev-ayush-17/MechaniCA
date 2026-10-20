from dataclasses import dataclass

from app.domain.errors import NotFound
from app.domain.notification import InAppNotification
from app.domain.user import Principal
from app.ports.clock import Clock
from app.ports.notification_repository import NotificationRepository


@dataclass(frozen=True)
class ManageNotifications:
    """Owner-only list, mark-read, and delete. Lookup is always under the caller."""

    notifications: NotificationRepository
    clock: Clock

    async def list_mine(self, principal: Principal) -> list[InAppNotification]:
        return await self.notifications.list_for_user(principal.user_id)

    async def mark_read(self, principal: Principal, notification_id: str) -> InAppNotification:
        updated = await self.notifications.mark_read(
            principal.user_id, notification_id, read_at=self.clock.now()
        )
        if updated is None:
            raise NotFound("We could not find that notification.")
        return updated

    async def delete(self, principal: Principal, notification_id: str) -> None:
        found = await self.notifications.delete(principal.user_id, notification_id)
        if not found:
            raise NotFound("We could not find that notification.")
