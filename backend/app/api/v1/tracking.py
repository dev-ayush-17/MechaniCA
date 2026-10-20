from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import create_tracking_link_dep, get_public_tracking_dep, principal_dep
from app.api.errors import error_responses
from app.application.create_tracking_link import CreateTrackingLink
from app.application.get_public_tracking import GetPublicTracking, PublicTracking
from app.domain.tracking import TrackingLink
from app.domain.user import Principal

links_router = APIRouter(
    prefix="/v1/bookings",
    tags=["tracking"],
    responses=error_responses(400, 401, 403, 404),
)

public_router = APIRouter(
    prefix="/v1/public/tracking",
    tags=["tracking"],
    responses=error_responses(404),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class TrackingLinkOut(_Camel):
    token: str
    path: str
    expires_at: datetime

    @classmethod
    def of(cls, link: TrackingLink) -> "TrackingLinkOut":
        return cls(
            token=link.token,
            path=f"/v1/public/tracking/{link.token}",
            expires_at=link.expires_at,
        )


class PublicTrackingOut(_Camel):
    mechanic_first_name: str
    vehicle_label: str
    status: str
    eta_seconds: int | None
    mechanic_lat: float | None
    mechanic_lng: float | None
    dest_lat: float
    dest_lng: float

    @classmethod
    def of(cls, view: PublicTracking) -> "PublicTrackingOut":
        return cls(
            mechanic_first_name=view.mechanic_first_name,
            vehicle_label=view.vehicle_label,
            status=view.status,
            eta_seconds=view.eta_seconds,
            mechanic_lat=view.mechanic_lat,
            mechanic_lng=view.mechanic_lng,
            dest_lat=view.dest_lat,
            dest_lng=view.dest_lng,
        )


@links_router.post("/{booking_id}/tracking-links", response_model=TrackingLinkOut, status_code=201)
async def create_tracking_link(
    booking_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[CreateTrackingLink, Depends(create_tracking_link_dep)],
) -> TrackingLinkOut:
    return TrackingLinkOut.of(await use_case.execute(principal, booking_id))


@public_router.get("/{token}", response_model=PublicTrackingOut)
async def get_public_tracking(
    token: str,
    use_case: Annotated[GetPublicTracking, Depends(get_public_tracking_dep)],
) -> PublicTrackingOut:
    return PublicTrackingOut.of(await use_case.execute(token))
