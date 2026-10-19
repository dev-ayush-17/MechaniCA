from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import (
    create_parts_proof_dep,
    hide_parts_proof_dep,
    list_parts_proofs_dep,
    principal_dep,
)
from app.api.errors import error_responses
from app.application.parts_proofs import CreatePartsProof, HidePartsProof, ListPartsProofs
from app.domain.parts_proof import PartsProof, ProofKind
from app.domain.user import Principal

proofs_router = APIRouter(
    prefix="/v1/bookings",
    tags=["proofs"],
    responses=error_responses(400, 401, 403, 404, 409),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class CreateProofRequest(_Camel):
    kind: ProofKind


class ProofOut(_Camel):
    id: str
    booking_id: str
    line_id: str
    kind: str
    path: str
    upload_url: str | None = None
    headers: dict[str, str] = {}
    captured_at: datetime
    hidden: bool
    metadata: dict[str, str]

    @classmethod
    def of(
        cls,
        proof: PartsProof,
        *,
        upload_url: str | None = None,
        headers: dict[str, str] | None = None,
    ) -> "ProofOut":
        return cls(
            id=proof.id,
            booking_id=proof.booking_id,
            line_id=proof.line_id,
            kind=proof.kind.value,
            path=proof.storage_path,
            upload_url=upload_url,
            headers=headers or {},
            captured_at=proof.captured_at,
            hidden=proof.hidden,
            metadata=dict(proof.metadata),
        )


class ProofListOut(_Camel):
    items: list[ProofOut]


@proofs_router.post(
    "/{booking_id}/lines/{line_id}/proofs",
    response_model=ProofOut,
    status_code=201,
)
async def create_parts_proof(
    booking_id: str,
    line_id: str,
    body: CreateProofRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[CreatePartsProof, Depends(create_parts_proof_dep)],
) -> ProofOut:
    proof, signed = await use_case.execute(principal, booking_id, line_id, kind=body.kind)
    return ProofOut.of(proof, upload_url=signed.upload_url, headers=signed.headers)


@proofs_router.get("/{booking_id}/proofs", response_model=ProofListOut)
async def list_parts_proofs(
    booking_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ListPartsProofs, Depends(list_parts_proofs_dep)],
) -> ProofListOut:
    items = await use_case.execute(principal, booking_id)
    return ProofListOut(items=[ProofOut.of(item) for item in items])


@proofs_router.post("/{booking_id}/proofs/{proof_id}/hide", response_model=ProofOut)
async def hide_parts_proof(
    booking_id: str,
    proof_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[HidePartsProof, Depends(hide_parts_proof_dep)],
) -> ProofOut:
    return ProofOut.of(await use_case.execute(principal, booking_id, proof_id))
