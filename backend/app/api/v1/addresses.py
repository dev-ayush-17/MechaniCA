from typing import Annotated

from fastapi import APIRouter, Depends, Header, Response
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import manage_addresses_dep, principal_dep
from app.api.errors import error_responses
from app.application.manage_addresses import ManageAddresses
from app.domain.address import Address
from app.domain.errors import InvalidInput
from app.domain.user import Principal

router = APIRouter(
    prefix="/v1/addresses",
    tags=["addresses"],
    responses=error_responses(400, 401, 403, 404, 409),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class AddressOut(_Camel):
    id: str
    owner_id: str
    label: str
    line1: str
    city: str
    pincode: str
    lat: float
    lng: float
    is_default: bool
    landmark: str | None = None

    @classmethod
    def of(cls, address: Address) -> "AddressOut":
        return cls(
            id=address.id,
            owner_id=address.owner_id,
            label=address.label,
            line1=address.line1,
            city=address.city,
            pincode=address.pincode,
            lat=address.lat,
            lng=address.lng,
            is_default=address.is_default,
            landmark=address.landmark,
        )


class AddressListOut(_Camel):
    items: list[AddressOut]


class CreateAddressRequest(_Camel):
    label: str
    line1: str
    city: str
    pincode: str
    lat: float
    lng: float
    landmark: str | None = None
    is_default: bool = False


class PatchAddressRequest(_Camel):
    label: str | None = None
    line1: str | None = None
    city: str | None = None
    pincode: str | None = None
    lat: float | None = None
    lng: float | None = None
    landmark: str | None = None
    is_default: bool | None = None


@router.get("", response_model=AddressListOut)
async def list_addresses(
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageAddresses, Depends(manage_addresses_dep)],
) -> AddressListOut:
    return AddressListOut(items=[AddressOut.of(item) for item in await use_case.list_for(principal)])


@router.post("", response_model=AddressOut, status_code=201)
async def create_address(
    body: CreateAddressRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageAddresses, Depends(manage_addresses_dep)],
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
) -> AddressOut:
    if not idempotency_key or not idempotency_key.strip():
        raise InvalidInput("Idempotency-Key is required.")
    address = await use_case.create(
        principal,
        label=body.label,
        line1=body.line1,
        city=body.city,
        pincode=body.pincode,
        lat=body.lat,
        lng=body.lng,
        landmark=body.landmark,
        is_default=body.is_default,
    )
    return AddressOut.of(address)


@router.patch("/{address_id}", response_model=AddressOut)
async def patch_address(
    address_id: str,
    body: PatchAddressRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageAddresses, Depends(manage_addresses_dep)],
) -> AddressOut:
    return AddressOut.of(
        await use_case.update(
            principal,
            address_id,
            label=body.label,
            line1=body.line1,
            city=body.city,
            pincode=body.pincode,
            lat=body.lat,
            lng=body.lng,
            landmark=body.landmark,
            is_default=body.is_default,
        )
    )


@router.delete("/{address_id}", status_code=204, response_class=Response)
async def delete_address(
    address_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageAddresses, Depends(manage_addresses_dep)],
) -> Response:
    await use_case.delete(principal, address_id)
    return Response(status_code=204)
