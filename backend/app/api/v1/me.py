from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Response
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import (
    bootstrap_user_dep,
    create_mechanic_draft_dep,
    manage_contacts_dep,
    principal_dep,
    register_device_dep,
    update_profile_dep,
    user_repository_dep,
)
from app.api.errors import error_responses
from app.application.bootstrap_user import BootstrapUser, Intent
from app.application.create_mechanic_draft import CreateMechanicDraft
from app.application.manage_contacts import ManageContacts
from app.application.register_device import RegisterDevice
from app.application.update_profile import UpdateProfile
from app.core.logging import log_info
from app.domain.contact import EmergencyContact
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
    email: str | None = None
    photo_path: str | None = None

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
            email=user.email,
            photo_path=user.photo_path,
        )


class PatchMeRequest(_Camel):
    name: str | None = None
    email: str | None = None


class ContactOut(_Camel):
    id: str
    name: str
    phone_e164: str

    @classmethod
    def of(cls, contact: EmergencyContact) -> "ContactOut":
        return cls(id=contact.id, name=contact.name, phone_e164=contact.phone_e164)


class ContactListOut(_Camel):
    items: list[ContactOut]


class CreateContactRequest(_Camel):
    name: str
    phone: str


@router.post("/bootstrap", response_model=UserOut, responses={201: {"model": UserOut}})
async def bootstrap(
    body: BootstrapRequest,
    response: Response,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[BootstrapUser, Depends(bootstrap_user_dep)],
    mechanic_draft: Annotated[CreateMechanicDraft, Depends(create_mechanic_draft_dep)],
) -> UserOut:
    """Create the caller's user document on first sign-in. Safe to repeat."""
    user, created = await use_case.execute(principal, name=body.name, intent=body.intent)
    if body.intent == Intent.MECHANIC:
        await mechanic_draft.execute(user.id)
    response.status_code = 201 if created else 200
    log_info("user bootstrapped", user_id=user.id, created=created)
    return UserOut.of(user)


class RegisterDeviceRequest(_Camel):
    token: str
    platform: str


class DeviceOut(_Camel):
    platform: str
    updated_at: datetime


@router.post("/devices", response_model=DeviceOut)
async def register_device(
    body: RegisterDeviceRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[RegisterDevice, Depends(register_device_dep)],
) -> DeviceOut:
    stored = await use_case.execute(principal, token=body.token, platform=body.platform)
    log_info("device registered", user_id=principal.user_id, platform=stored.platform.value)
    return DeviceOut(platform=stored.platform.value, updated_at=stored.updated_at)


@router.get("", response_model=UserOut)
async def me(
    principal: Annotated[Principal, Depends(principal_dep)],
    users: Annotated[UserRepository, Depends(user_repository_dep)],
) -> UserOut:
    user = await users.get(principal.user_id)
    if user is None:
        raise NotFound("Finish sign-in first.")
    return UserOut.of(user)


@router.patch("", response_model=UserOut)
async def patch_me(
    body: PatchMeRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[UpdateProfile, Depends(update_profile_dep)],
) -> UserOut:
    return UserOut.of(await use_case.execute(principal, name=body.name, email=body.email))


@router.get("/contacts", response_model=ContactListOut)
async def list_contacts(
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageContacts, Depends(manage_contacts_dep)],
) -> ContactListOut:
    return ContactListOut(
        items=[ContactOut.of(item) for item in await use_case.list_for(principal)]
    )


@router.post("/contacts", response_model=ContactOut, status_code=201)
async def create_contact(
    body: CreateContactRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageContacts, Depends(manage_contacts_dep)],
) -> ContactOut:
    return ContactOut.of(await use_case.create(principal, name=body.name, phone=body.phone))


@router.delete("/contacts/{contact_id}", status_code=204, response_class=Response)
async def delete_contact(
    contact_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageContacts, Depends(manage_contacts_dep)],
) -> Response:
    await use_case.delete(principal, contact_id)
    return Response(status_code=204)
