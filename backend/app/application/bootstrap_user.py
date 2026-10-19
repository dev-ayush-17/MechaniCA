from dataclasses import dataclass
from enum import StrEnum

from app.domain.errors import RoleExists, Unauthenticated
from app.domain.user import Principal, Role, User, UserStatus
from app.ports.clock import Clock
from app.ports.role_claims import RoleClaims
from app.ports.user_repository import UserRepository


class Intent(StrEnum):
    CUSTOMER = "customer"
    MECHANIC = "mechanic"


_INTENT_ROLE = {Intent.CUSTOMER: Role.CUSTOMER, Intent.MECHANIC: Role.MECHANIC}


@dataclass(frozen=True)
class BootstrapUser:
    """First call after sign-in. Creates users/{uid} once and sets the role claim.

    The role comes from the intent, which only ever grants customer or mechanic. It
    is never copied from the request body, and privileged roles are never grantable here.
    """

    users: UserRepository
    claims: RoleClaims
    clock: Clock
    auth_provider: str

    async def execute(
        self, principal: Principal, *, name: str | None, intent: Intent
    ) -> tuple[User, bool]:
        """Returns the user and whether this call created it."""
        wanted = _INTENT_ROLE[intent]
        existing = await self.users.get(principal.user_id)
        if existing is not None:
            if existing.role != wanted:
                raise RoleExists("This phone is already registered with another role.")
            if principal.role != existing.role:
                # The document wins; refresh a stale claim.
                await self.claims.set_role(existing.id, existing.role)
            return existing, False

        if principal.role not in (Role.CUSTOMER, wanted):
            raise RoleExists("This phone is already registered with another role.")
        if principal.phone_e164 is None:
            raise Unauthenticated("Sign in again.")

        now = self.clock.now()
        user = User(
            id=principal.user_id,
            role=wanted,
            name=(name or "").strip(),
            phone_e164=principal.phone_e164,
            status=UserStatus.ACTIVE,
            auth_provider=self.auth_provider,
            auth_subject=principal.user_id,
            created_at=now,
            updated_at=now,
        )
        saved = await self.users.upsert(user)
        await self.claims.set_role(saved.id, saved.role)
        return saved, True
