from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class VehicleType(StrEnum):
    TWO_WHEELER = "two_wheeler"
    FOUR_WHEELER = "four_wheeler"


@dataclass(frozen=True)
class Vehicle:
    id: str
    owner_id: str
    vehicle_type: VehicleType
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
