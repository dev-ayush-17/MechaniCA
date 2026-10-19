from app.domain.vehicle import Vehicle


class FakeVehicleRepository:
    """In-memory vehicles subcollection keyed by owner id."""

    def __init__(self) -> None:
        self._by_owner: dict[str, dict[str, Vehicle]] = {}

    async def list_by_owner(self, owner_id: str) -> list[Vehicle]:
        return list(self._by_owner.get(owner_id, {}).values())

    async def get(self, vehicle_id: str, owner_id: str) -> Vehicle | None:
        return self._by_owner.get(owner_id, {}).get(vehicle_id)

    async def save(self, vehicle: Vehicle) -> Vehicle:
        bucket = self._by_owner.setdefault(vehicle.owner_id, {})
        bucket[vehicle.id] = vehicle
        return vehicle

    async def delete(self, vehicle_id: str, owner_id: str) -> None:
        self._by_owner.get(owner_id, {}).pop(vehicle_id, None)
