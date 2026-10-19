from typing import Protocol

from app.domain.user import Principal


class AuthVerifier(Protocol):
    """Turns a bearer token into a Principal (docs/prd/08-port-catalog.md)."""

    async def verify(self, id_token: str, *, check_revoked: bool = False) -> Principal:
        """Raises Unauthenticated when the token is bad, expired, revoked, or for another
        project. Raises Unavailable when the vendor cannot be reached."""
        ...
