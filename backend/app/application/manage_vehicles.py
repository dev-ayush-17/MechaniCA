from dataclasses import dataclass, replace
from uuid import uuid4

from app.domain.errors import Conflict, InvalidInput, NotFound
from app.domain.plate import is_valid_indian_plate, normalize_plate
from app.domain.user import Principal, Role
from app.domain.vehicle import Vehicle, VehicleType
from app.ports.clock import Clock
from app.ports.vehicle_repository import VehicleRepository

MAX_VEHICLES = 10
MIN_YEAR = 1980


@dataclass(frozen=True)
class ManageVehicles:
    vehicles: VehicleRepository
    clock: Clock

    def _ensure_customer(self, principal: Principal) -> None:
        if principal.role != Role.CUSTOMER:
            raise NotFound("We could not find that.")

    async def list_for(self, principal: Principal) -> list[Vehicle]:
        self._ensure_customer(principal)
        return await self.vehicles.list_by_owner(principal.user_id)

    async def get_for(self, principal: Principal, vehicle_id: str) -> Vehicle:
        self._ensure_customer(principal)
        vehicle = await self.vehicles.get(vehicle_id, principal.user_id)
        if vehicle is None:
            raise NotFound("We could not find that vehicle.")
        return vehicle

    async def create(
        self,
        principal: Principal,
        *,
        vehicle_type: VehicleType,
        brand: str,
        model: str,
        year: int,
        registration_number: str,
        fuel_type: str | None,
        color: str | None,
        odometer_km: int | None,
        is_primary: bool,
    ) -> Vehicle:
        self._ensure_customer(principal)
        self._validate_fields(
            brand=brand,
            model=model,
            year=year,
            registration_number=registration_number,
            odometer_km=odometer_km,
        )
        existing = await self.vehicles.list_by_owner(principal.user_id)
        if len(existing) >= MAX_VEHICLES:
            raise InvalidInput("You can save up to 10 vehicles.")
        plate = normalize_plate(registration_number)
        if any(v.registration_number == plate for v in existing):
            raise Conflict("This registration number is already saved.")
        now = self.clock.now()
        make_primary = is_primary or not any(v.is_primary for v in existing)
        vehicle = Vehicle(
            id=str(uuid4()),
            owner_id=principal.user_id,
            vehicle_type=vehicle_type,
            brand=brand.strip(),
            model=model.strip(),
            year=year,
            registration_number=plate,
            fuel_type=fuel_type,
            color=color,
            odometer_km=odometer_km,
            is_primary=make_primary,
            created_at=now,
            updated_at=now,
            version=1,
        )
        if make_primary:
            await self._clear_primary(principal.user_id, except_id=vehicle.id)
        return await self.vehicles.save(vehicle)

    async def update(
        self,
        principal: Principal,
        vehicle_id: str,
        *,
        expected_version: int,
        vehicle_type: VehicleType | None,
        brand: str | None,
        model: str | None,
        year: int | None,
        registration_number: str | None,
        fuel_type: str | None,
        color: str | None,
        odometer_km: int | None,
        is_primary: bool | None,
    ) -> Vehicle:
        self._ensure_customer(principal)
        current = await self.vehicles.get(vehicle_id, principal.user_id)
        if current is None:
            raise NotFound("We could not find that vehicle.")
        if current.version != expected_version:
            raise Conflict("This vehicle was updated elsewhere. Refresh and try again.")
        new_brand = brand.strip() if brand is not None else current.brand
        new_model = model.strip() if model is not None else current.model
        new_year = year if year is not None else current.year
        new_plate = (
            normalize_plate(registration_number)
            if registration_number is not None
            else current.registration_number
        )
        new_type = vehicle_type if vehicle_type is not None else current.vehicle_type
        new_odometer = odometer_km if odometer_km is not None else current.odometer_km
        self._validate_fields(
            brand=new_brand,
            model=new_model,
            year=new_year,
            registration_number=new_plate,
            odometer_km=new_odometer,
        )
        if new_plate != current.registration_number:
            others = await self.vehicles.list_by_owner(principal.user_id)
            if any(v.registration_number == new_plate and v.id != vehicle_id for v in others):
                raise Conflict("This registration number is already saved.")
        new_primary = current.is_primary if is_primary is None else is_primary
        updated = replace(
            current,
            vehicle_type=new_type,
            brand=new_brand,
            model=new_model,
            year=new_year,
            registration_number=new_plate,
            fuel_type=fuel_type if fuel_type is not None else current.fuel_type,
            color=color if color is not None else current.color,
            odometer_km=new_odometer,
            is_primary=new_primary,
            updated_at=self.clock.now(),
            version=current.version + 1,
        )
        if is_primary is True:
            await self._clear_primary(principal.user_id, except_id=vehicle_id)
            updated = replace(updated, is_primary=True)
        return await self.vehicles.save(updated)

    async def delete(self, principal: Principal, vehicle_id: str) -> None:
        self._ensure_customer(principal)
        current = await self.vehicles.get(vehicle_id, principal.user_id)
        if current is None:
            raise NotFound("We could not find that vehicle.")
        await self.vehicles.delete(vehicle_id, principal.user_id)

    async def _clear_primary(self, owner_id: str, *, except_id: str) -> None:
        for v in await self.vehicles.list_by_owner(owner_id):
            if v.is_primary and v.id != except_id:
                await self.vehicles.save(
                    replace(
                        v,
                        is_primary=False,
                        updated_at=self.clock.now(),
                        version=v.version + 1,
                    )
                )

    def _validate_fields(
        self,
        *,
        brand: str,
        model: str,
        year: int,
        registration_number: str,
        odometer_km: int | None,
    ) -> None:
        if not brand.strip() or not model.strip():
            raise InvalidInput("Brand and model are required.")
        max_year = self.clock.now().year + 1
        if year < MIN_YEAR or year > max_year:
            raise InvalidInput(f"Year must be between {MIN_YEAR} and {max_year}.")
        if not is_valid_indian_plate(registration_number):
            raise InvalidInput(
                "Enter a valid registration number.",
                fields={"registrationNumber": "Enter a valid registration number."},
            )
        if odometer_km is not None and (odometer_km < 0 or odometer_km > 2_000_000):
            raise InvalidInput("Odometer must be between 0 and 2,000,000 km.")
