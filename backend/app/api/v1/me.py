from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Response
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import bootstrap_user_dep, principal_dep, user_repository_dep
from app.api.errors import error_responses
from app.application.bootstrap_user import BootstrapUser, Intent
from app.core.logging import log_info
from app.domain.errors import NotFound
from app.domain.user import Principal, User
from app.ports.user_repository import UserRepository

router = APIRouter(prefix="/v1/me", tags=["me"], responses=error_responses(400, 401, 403, 404, 409))


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class BootstrapRequest(_Camel):
    """`role` is deliberately not a field: the server derives it from `intent`."""

    name: str | None = None
    intent: Intent


class UserOut(_Camel):
    id: str
    role: str
    name: str
    phone_e164: str
    status: str
    created_at: datetime
    updated_at: datetime

    @classmethod
    def of(cls, user: User) -> "UserOut":
        return cls(
            id=user.id,
            role=user.role.value,
            name=user.name,
            phone_e164=user.phone_e164,
            status=user.status.value,
            created_at=user.created_at,
            updated_at=user.updated_at,
        )


@router.post("/bootstrap", response_model=UserOut, responses={201: {"model": UserOut}})
async def bootstrap(
    body: BootstrapRequest,
    response: Response,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[BootstrapUser, Depends(bootstrap_user_dep)],
) -> UserOut:
    """Create the caller's user document on first sign-in. Safe to repeat."""
    user, created = await use_case.execute(principal, name=body.name, intent=body.intent)
    response.status_code = 201 if created else 200
    log_info("user bootstrapped", user_id=user.id, created=created)
    return UserOut.of(user)


@router.get("", response_model=UserOut)
async def me(
    principal: Annotated[Principal, Depends(principal_dep)],
    users: Annotated[UserRepository, Depends(user_repository_dep)],
) -> UserOut:
    user = await users.get(principal.user_id)
    if user is None:
        raise NotFound("Finish sign-in first.")
    return UserOut.of(user)
