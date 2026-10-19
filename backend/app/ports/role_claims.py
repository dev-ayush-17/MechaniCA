from typing import Protocol

from app.domain.user import Role


class RoleClaims(Protocol):
    """Writes custom claims. Bootstrap sets `role`; verification sets `mechanicVerified`."""

    async def set_role(self, user_id: str, role: Role) -> None: ...

    async def set_mechanic_verified(self, user_id: str, verified: bool) -> None: ...
