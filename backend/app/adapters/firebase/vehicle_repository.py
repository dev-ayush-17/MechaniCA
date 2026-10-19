from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.domain.vehicle import Vehicle, VehicleType


def _parse_time(value: object) -> datetime:
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


def _to_doc(vehicle: Vehicle) -> dict[str, object]:
    return {
        "ownerId": vehicle.owner_id,
        "vehicleType": vehicle.vehicle_type.value,
        "brand": vehicle.brand,
        "model": vehicle.model,
        "year": vehicle.year,
        "registrationNumber": vehicle.registration_number,
        "fuelType": vehicle.fuel_type,
        "color": vehicle.color,
        "odometerKm": vehicle.odometer_km,
        "isPrimary": vehicle.is_primary,
        "createdAt": vehicle.created_at,
        "updatedAt": vehicle.updated_at,
        "version": vehicle.version,
    }


def _from_doc(vehicle_id: str, data: dict[str, object]) -> Vehicle:
    return Vehicle(
        id=vehicle_id,
        owner_id=str(data["ownerId"]),
        vehicle_type=VehicleType(str(data["vehicleType"])),
        brand=str(data["brand"]),
        model=str(data["model"]),
        year=int(str(data["year"])),
        registration_number=str(data["registrationNumber"]),
        fuel_type=data.get("fuelType"),  # type: ignore[arg-type]
        color=data.get("color"),  # type: ignore[arg-type]
        odometer_km=data.get("odometerKm"),  # type: ignore[arg-type]
        is_primary=bool(data.get("isPrimary", False)),
        created_at=_parse_time(data["createdAt"]),
        updated_at=_parse_time(data["updatedAt"]),
        version=int(str(data.get("version", 1))),
    )


class FirestoreVehicleRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self, owner_id: str) -> Any:
        return self._db.collection("users").document(owner_id).collection("vehicles")

    async def list_by_owner(self, owner_id: str) -> list[Vehicle]:
        snaps = self._col(owner_id).stream()
        return [_from_doc(s.id, s.to_dict() or {}) for s in snaps]

    async def get(self, vehicle_id: str, owner_id: str) -> Vehicle | None:
        snap = self._col(owner_id).document(vehicle_id).get()
        if not snap.exists:
            return None
        return _from_doc(snap.id, snap.to_dict() or {})

    async def save(self, vehicle: Vehicle) -> Vehicle:
        self._col(vehicle.owner_id).document(vehicle.id).set(_to_doc(vehicle))
        return vehicle

    async def delete(self, vehicle_id: str, owner_id: str) -> None:
        self._col(owner_id).document(vehicle_id).delete()
