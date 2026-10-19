from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Header, Response
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import manage_vehicles_dep, principal_dep
from app.api.errors import error_responses
from app.application.manage_vehicles import ManageVehicles
from app.domain.errors import InvalidInput
from app.domain.user import Principal
from app.domain.vehicle import Vehicle, VehicleType

router = APIRouter(
    prefix="/v1/vehicles", tags=["vehicles"], responses=error_responses(400, 401, 403, 404, 409)
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class VehicleOut(_Camel):
    id: str
    owner_id: str
    vehicle_type: str
    brand: str
    model: str
    year: int
    registration_number: str
    fuel_type: str | None
    color: str | None
    odometer_km: int | None
    is_primary: bool
    created_at: datetime
    updated_at: datetime
    version: int

    @classmethod
    def of(cls, vehicle: Vehicle) -> "VehicleOut":
        return cls(
            id=vehicle.id,
            owner_id=vehicle.owner_id,
            vehicle_type=vehicle.vehicle_type.value,
            brand=vehicle.brand,
            model=vehicle.model,
            year=vehicle.year,
            registration_number=vehicle.registration_number,
            fuel_type=vehicle.fuel_type,
            color=vehicle.color,
            odometer_km=vehicle.odometer_km,
            is_primary=vehicle.is_primary,
            created_at=vehicle.created_at,
            updated_at=vehicle.updated_at,
            version=vehicle.version,
        )


class VehicleListOut(_Camel):
    items: list[VehicleOut]


class CreateVehicleRequest(_Camel):
    vehicle_type: VehicleType = VehicleType.TWO_WHEELER
    brand: str
    model: str
    year: int
    registration_number: str
    fuel_type: str | None = None
    color: str | None = None
    odometer_km: int | None = None
    is_primary: bool = False


class PatchVehicleRequest(_Camel):
    version: int
    vehicle_type: VehicleType | None = None
    brand: str | None = None
    model: str | None = None
    year: int | None = None
    registration_number: str | None = None
    fuel_type: str | None = None
    color: str | None = None
    odometer_km: int | None = None
    is_primary: bool | None = None


@router.get("", response_model=VehicleListOut)
async def list_vehicles(
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageVehicles, Depends(manage_vehicles_dep)],
) -> VehicleListOut:
    items = await use_case.list_for(principal)
    return VehicleListOut(items=[VehicleOut.of(v) for v in items])


@router.post("", response_model=VehicleOut, status_code=201)
async def create_vehicle(
    body: CreateVehicleRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageVehicles, Depends(manage_vehicles_dep)],
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
) -> VehicleOut:
    if not idempotency_key or not idempotency_key.strip():
        raise InvalidInput("Idempotency-Key is required.")
    vehicle = await use_case.create(
        principal,
        vehicle_type=body.vehicle_type,
        brand=body.brand,
        model=body.model,
        year=body.year,
        registration_number=body.registration_number,
        fuel_type=body.fuel_type,
        color=body.color,
        odometer_km=body.odometer_km,
        is_primary=body.is_primary,
    )
    return VehicleOut.of(vehicle)


@router.patch("/{vehicle_id}", response_model=VehicleOut)
async def patch_vehicle(
    vehicle_id: str,
    body: PatchVehicleRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageVehicles, Depends(manage_vehicles_dep)],
) -> VehicleOut:
    vehicle = await use_case.update(
        principal,
        vehicle_id,
        expected_version=body.version,
        vehicle_type=body.vehicle_type,
        brand=body.brand,
        model=body.model,
        year=body.year,
        registration_number=body.registration_number,
        fuel_type=body.fuel_type,
        color=body.color,
        odometer_km=body.odometer_km,
        is_primary=body.is_primary,
    )
    return VehicleOut.of(vehicle)


@router.delete("/{vehicle_id}", status_code=204, response_class=Response)
async def delete_vehicle(
    vehicle_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageVehicles, Depends(manage_vehicles_dep)],
) -> Response:
    await use_case.delete(principal, vehicle_id)
    return Response(status_code=204)
