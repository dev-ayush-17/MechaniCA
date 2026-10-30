import asyncio
from typing import Any

import firebase_admin
from firebase_admin import auth as fb_auth

from app.domain.errors import Unauthenticated, Unavailable
from app.domain.user import Principal, Role


class FirebaseAuth:
    """AuthVerifier and RoleClaims over the Firebase Admin SDK.

    Binding the project id makes the SDK check the token audience. With
    FIREBASE_AUTH_EMULATOR_HOST set the SDK accepts emulator tokens, so the same
    adapter serves local work.
    """

    def __init__(self, project_id: str) -> None:
        self._app = firebase_admin.initialize_app(options={"projectId": project_id})

    async def verify(self, id_token: str, *, check_revoked: bool = False) -> Principal:
        try:
            claims: dict[str, Any] = await asyncio.to_thread(
                fb_auth.verify_id_token, id_token, self._app, check_revoked
            )
        except fb_auth.CertificateFetchError as exc:
            raise Unavailable("Sign-in is unavailable. Try again.") from exc
        except (
            ValueError,
            fb_auth.InvalidIdTokenError,
            fb_auth.RevokedIdTokenError,
            fb_auth.UserDisabledError,
        ) as exc:
            # The SDK message can echo token content, so it is not passed on.
            raise Unauthenticated("Sign in again.") from exc
        return Principal(
            user_id=str(claims["uid"]),
            role=_role_from(claims.get("role")),
            phone_e164=claims.get("phone_number"),
            mechanic_verified=bool(claims.get("mechanicVerified", False)),
        )

    async def set_role(self, user_id: str, role: Role) -> None:
        await asyncio.to_thread(
            fb_auth.set_custom_user_claims, user_id, {"role": role.value}, self._app
        )

    async def set_mechanic_verified(self, user_id: str, verified: bool) -> None:
        def _merge() -> None:
            user = fb_auth.get_user(user_id, app=self._app)
            claims = dict(user.custom_claims or {})
            claims["mechanicVerified"] = verified
            fb_auth.set_custom_user_claims(user_id, claims, self._app)

        await asyncio.to_thread(_merge)


def _role_from(value: str | None) -> Role:
    if value is None:
        return Role.CUSTOMER
    try:
        return Role(value)
    except ValueError:
        return Role.CUSTOMER
