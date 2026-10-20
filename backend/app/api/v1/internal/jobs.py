from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import (
    expire_extra_line_dep,
    expire_offer_dep,
    require_internal_job_dep,
    sweep_expired_offers_dep,
)
from app.api.errors import error_responses
from app.application.expire_extra_line import ExpireExtraLine
from app.application.expire_offer import ExpireOffer
from app.application.sweep_jobs import SweepExpiredOffers

router = APIRouter(
    prefix="/v1/internal/jobs",
    tags=["internal"],
    responses=error_responses(401, 404),
    dependencies=[Depends(require_internal_job_dep)],
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class DispatchTimeoutRequest(_Camel):
    offer_id: str


class ExtraWorkTimeoutRequest(_Camel):
    booking_id: str
    line_id: str


class JobOk(_Camel):
    ok: bool = True
    expired: int = 0


@router.post("/dispatch-timeout", response_model=JobOk)
async def dispatch_timeout(
    body: DispatchTimeoutRequest,
    use_case: Annotated[ExpireOffer, Depends(expire_offer_dep)],
) -> JobOk:
    await use_case.execute(body.offer_id)
    return JobOk()


@router.post("/dispatch-sweep", response_model=JobOk)
async def dispatch_sweep(
    use_case: Annotated[SweepExpiredOffers, Depends(sweep_expired_offers_dep)],
) -> JobOk:
    expired = await use_case.execute()
    return JobOk(expired=expired)


@router.post("/extra-work-timeout", response_model=JobOk)
async def extra_work_timeout(
    body: ExtraWorkTimeoutRequest,
    use_case: Annotated[ExpireExtraLine, Depends(expire_extra_line_dep)],
) -> JobOk:
    await use_case.execute(body.booking_id, body.line_id)
    return JobOk()
