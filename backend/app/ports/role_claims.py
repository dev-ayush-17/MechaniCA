from typing import Protocol

from app.domain.user import Role


class RoleClaims(Protocol):
    """Writes the `role` custom claim. Needed because bootstrap sets the claim
    (docs/prd/11-authentication.md) and the verifier only reads it."""

    async def set_role(self, user_id: str, role: Role) -> None: ...
