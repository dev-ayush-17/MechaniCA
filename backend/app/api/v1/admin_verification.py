from typing import Annotated

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import admin_principal_dep, verify_mechanic_dep
from app.api.errors import REQUEST_ID_HEADER, error_responses
from app.api.v1.mechanic import MechanicOut
from app.application.verify_mechanic import VerificationDecision, VerifyMechanic
from app.domain.user import Principal

router = APIRouter(
    prefix="/v1/admin/mechanics",
    tags=["admin"],
    responses=error_responses(400, 401, 403, 404, 409),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class VerificationRequest(_Camel):
    decision: VerificationDecision
    reason: str | None = None


@router.post("/{mechanic_id}/verification", response_model=MechanicOut)
async def decide_verification(
    mechanic_id: str,
    body: VerificationRequest,
    request: Request,
    principal: Annotated[Principal, Depends(admin_principal_dep)],
    use_case: Annotated[VerifyMechanic, Depends(verify_mechanic_dep)],
) -> MechanicOut:
    request_id = request.headers.get(REQUEST_ID_HEADER, getattr(request.state, "request_id", ""))
    mechanic = await use_case.execute(
        principal,
        mechanic_id,
        decision=body.decision,
        reason=body.reason,
        request_id=str(request_id),
        record_audit=True,
    )
    return MechanicOut.of(mechanic)
