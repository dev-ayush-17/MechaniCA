from dataclasses import dataclass, replace
from uuid import uuid4

from app.domain.audit import AuditEvent
from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.user import Principal, Role, User, UserStatus
from app.ports.audit_log import AuditLog
from app.ports.clock import Clock
from app.ports.user_repository import UserRepository


@dataclass(frozen=True)
class SuspendUser:
    users: UserRepository
    audit: AuditLog
    clock: Clock

    async def execute(
        self, principal: Principal, user_id: str, *, reason: str, request_id: str
    ) -> User:
        if principal.role not in {Role.ADMIN, Role.SUPER_ADMIN}:
            raise PermissionDenied("Admin access required.")
        cleaned = reason.strip()
        if not cleaned:
            raise InvalidInput("Add a reason.", fields={"reason": "required"})
        user = await self.users.get(user_id)
        if user is None:
            raise NotFound("We could not find that user.")
        now = self.clock.now()
        saved = await self.users.upsert(replace(user, status=UserStatus.SUSPENDED, updated_at=now))
        await self.audit.append(
            AuditEvent(
                id=uuid4().hex,
                actor_id=principal.user_id,
                role=principal.role.value,
                action="user_suspend",
                target_type="user",
                target_id=user_id,
                summary=cleaned,
                request_id=request_id,
                created_at=now,
            )
        )
        return saved
