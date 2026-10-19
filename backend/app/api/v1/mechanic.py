from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

from app.api.deps import (
    create_mechanic_draft_dep,
    mechanic_heartbeat_dep,
    mechanic_repository_dep,
    principal_dep,
    require_mechanic_dep,
    set_mechanic_availability_dep,
    sign_upload_dep,
    submit_mechanic_application_dep,
)
from app.api.errors import error_responses
from app.application.create_mechanic_draft import CreateMechanicDraft
from app.application.mechanic_heartbeat import MechanicHeartbeat
from app.application.set_mechanic_availability import SetMechanicAvailability
from app.application.sign_upload import SignUpload
from app.application.submit_mechanic_application import (
    DocumentInput,
    ServiceAreaInput,
    SubmitMechanicApplication,
)
from app.domain.mechanic import DocumentKind, Mechanic
from app.domain.user import Principal
from app.ports.mechanic_repository import MechanicRepository

router = APIRouter(prefix="/v1/mechanic", tags=["mechanic"], responses=error_responses(400, 401, 403, 404, 409))


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class ServiceAreaOut(_Camel):
    lat: float
    lng: float
    radius_km: float
    geohash: str


class MechanicOut(_Camel):
    id: str
    display_name: str
    photo_path: str
    years_experience: int
    languages: list[str]
    service_area: ServiceAreaOut | None
    verified: bool
    verification_status: str
    online: bool
    last_heartbeat_at: datetime | None
    rating_avg: float
    rating_count: int
    version: int
    rejection_reason: str | None = None

    @classmethod
    def of(cls, mechanic: Mechanic) -> "MechanicOut":
        area = mechanic.service_area
        return cls(
            id=mechanic.id,
            display_name=mechanic.display_name,
            photo_path=mechanic.photo_path,
            years_experience=mechanic.years_experience,
            languages=list(mechanic.languages),
            service_area=(
                ServiceAreaOut(
                    lat=area.lat,
                    lng=area.lng,
                    radius_km=area.radius_km,
                    geohash=area.geohash,
                )
                if area
                else None
            ),
            verified=mechanic.verified,
            verification_status=mechanic.verification_status.value,
            online=mechanic.online,
            last_heartbeat_at=mechanic.last_heartbeat_at,
            rating_avg=mechanic.rating_avg,
            rating_count=mechanic.rating_count,
            version=mechanic.version,
            rejection_reason=mechanic.rejection_reason,
        )


class DocumentIn(_Camel):
    kind: DocumentKind
    storage_path: str


class ServiceAreaIn(_Camel):
    lat: float
    lng: float
    radius_km: float = Field(ge=1, le=20)


class ApplicationRequest(_Camel):
    display_name: str
    photo_path: str
    years_experience: int
    languages: list[str]
    service_area: ServiceAreaIn
    documents: list[DocumentIn]


class AvailabilityRequest(_Camel):
    online: bool


@router.get("", response_model=MechanicOut)
async def get_mechanic_profile(
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    draft: Annotated[CreateMechanicDraft, Depends(create_mechanic_draft_dep)],
) -> MechanicOut:
    mechanic = await mechanics.get(principal.user_id)
    if mechanic is None:
        mechanic = await draft.execute(principal.user_id)
    return MechanicOut.of(mechanic)


@router.post("/application", response_model=MechanicOut)
async def submit_application(
    body: ApplicationRequest,
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[SubmitMechanicApplication, Depends(submit_mechanic_application_dep)],
) -> MechanicOut:
    mechanic = await use_case.execute(
        principal,
        display_name=body.display_name,
        photo_path=body.photo_path,
        years_experience=body.years_experience,
        languages=body.languages,
        service_area=ServiceAreaInput(
            lat=body.service_area.lat,
            lng=body.service_area.lng,
            radius_km=body.service_area.radius_km,
        ),
        documents=[
            DocumentInput(kind=d.kind, storage_path=d.storage_path) for d in body.documents
        ],
    )
    return MechanicOut.of(mechanic)


@router.post("/availability", response_model=MechanicOut)
async def set_availability(
    body: AvailabilityRequest,
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[SetMechanicAvailability, Depends(set_mechanic_availability_dep)],
) -> MechanicOut:
    mechanic = await use_case.execute(principal, online=body.online)
    return MechanicOut.of(mechanic)


@router.post("/heartbeat", response_model=MechanicOut)
async def heartbeat(
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[MechanicHeartbeat, Depends(mechanic_heartbeat_dep)],
) -> MechanicOut:
    mechanic = await use_case.execute(principal)
    return MechanicOut.of(mechanic)


upload_router = APIRouter(
    prefix="/v1/uploads",
    tags=["uploads"],
    responses=error_responses(400, 401, 403),
)


class SignUploadRequest(_Camel):
    path: str
    content_type: str
    max_bytes: int = Field(le=5 * 1024 * 1024)


class SignUploadOut(_Camel):
    upload_url: str
    path: str
    headers: dict[str, str]


@upload_router.post("/sign", response_model=SignUploadOut)
async def sign_upload(
    body: SignUploadRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[SignUpload, Depends(sign_upload_dep)],
) -> SignUploadOut:
    signed = await use_case.execute(
        principal,
        path=body.path,
        content_type=body.content_type,
        max_bytes=body.max_bytes,
    )
    return SignUploadOut(
        upload_url=signed.upload_url, path=signed.path, headers=signed.headers
    )
