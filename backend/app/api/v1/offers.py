from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import dispatch_service_dep, require_mechanic_dep
from app.api.errors import error_responses
from app.application.dispatch import SequentialDispatch
from app.domain.dispatch import Offer, OfferStatus
from app.domain.errors import NotFound
from app.domain.user import Principal

router = APIRouter(
    prefix="/v1/offers",
    tags=["offers"],
    responses=error_responses(400, 401, 403, 404, 409),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class OfferOut(_Camel):
    id: str
    booking_id: str
    mechanic_id: str
    status: str
    expires_at: datetime
    attempt: int
    score: float
    distance_km: float
    service_name: str
    total_paise: int
    vehicle_type: str = ""

    @classmethod
    def of(
        cls,
        offer: Offer,
        *,
        service_name: str,
        total_paise: int,
        vehicle_type: str = "",
    ) -> "OfferOut":
        return cls(
            id=offer.id,
            booking_id=offer.booking_id,
            mechanic_id=offer.mechanic_id,
            status=offer.status.value,
            expires_at=offer.expires_at,
            attempt=offer.attempt,
            score=offer.score,
            distance_km=offer.distance_km,
            service_name=service_name,
            total_paise=total_paise,
            vehicle_type=vehicle_type,
        )


class BookingAcceptOut(_Camel):
    id: str
    status: str
    mechanic_id: str | None
    version: int


async def _offer_out(use_case: SequentialDispatch, offer: Offer) -> OfferOut:
    booking = await use_case.bookings.get(offer.booking_id)
    return OfferOut.of(
        offer,
        service_name=booking.service_name if booking else "",
        total_paise=booking.total_paise if booking else 0,
    )


@router.get("/open", response_model=OfferOut)
async def get_open_offer(
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[SequentialDispatch, Depends(dispatch_service_dep)],
) -> OfferOut:
    open_offers = [
        item
        for item in await use_case.offers.list_by_mechanic(principal.user_id)
        if item.status is OfferStatus.OPEN
    ]
    if not open_offers:
        raise NotFound("No open offer.")
    return await _offer_out(use_case, open_offers[0])


@router.get("/{offer_id}", response_model=OfferOut)
async def get_offer(
    offer_id: str,
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[SequentialDispatch, Depends(dispatch_service_dep)],
) -> OfferOut:
    offer = await use_case.offers.get(offer_id)
    if offer is None or offer.mechanic_id != principal.user_id:
        raise NotFound("We could not find that offer.")
    return await _offer_out(use_case, offer)


@router.post("/{offer_id}/accept", response_model=BookingAcceptOut)
async def accept_offer(
    offer_id: str,
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[SequentialDispatch, Depends(dispatch_service_dep)],
) -> BookingAcceptOut:
    booking = await use_case.accept(offer_id, principal.user_id)
    return BookingAcceptOut(
        id=booking.id,
        status=booking.status.value,
        mechanic_id=booking.mechanic_id,
        version=booking.version,
    )


@router.post("/{offer_id}/reject", status_code=204)
async def reject_offer(
    offer_id: str,
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[SequentialDispatch, Depends(dispatch_service_dep)],
) -> None:
    await use_case.reject(offer_id, principal.user_id)
