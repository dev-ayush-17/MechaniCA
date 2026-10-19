from app.core.config import FAKE_AUTH_ENVS, Env
from app.domain.errors import Unauthenticated
from app.domain.user import Principal, Role

FAKE_TOKEN_PREFIX = "fake"  # noqa: S105 - a format marker, not a credential


class FakeAuth:
    """Dev and test stand-in for the vendor token check, and the role-claim store.

    Token format: `fake:<uid>:<phoneE164>`. It never works when `env` is staging or prod,
    so the demo credentials cannot sign anyone in on a real deployment.
    """

    def __init__(self, env: Env) -> None:
        if env not in FAKE_AUTH_ENVS:
            raise ValueError("FakeAuth is only available when app_env is dev or test")
        self._claims: dict[str, Role] = {}

    async def verify(self, id_token: str, *, check_revoked: bool = False) -> Principal:
        parts = id_token.split(":")
        if len(parts) != 3 or parts[0] != FAKE_TOKEN_PREFIX or not parts[1] or not parts[2]:
            raise Unauthenticated("Sign in again.")
        _, uid, phone = parts
        return Principal(
            user_id=uid,
            role=self._claims.get(uid, Role.CUSTOMER),
            phone_e164=phone,
        )

    async def set_role(self, user_id: str, role: Role) -> None:
        self._claims[user_id] = role
