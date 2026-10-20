from typing import Protocol

from app.domain.location import BookingGate, LocationPoint, LocationSnapshot


class LocationTrackingService(Protocol):
    """RTDB-backed live points. Clients write own nodes; the API writes gates."""

    async def publish(self, booking_id: str, role: str, point: LocationPoint) -> None: ...

    async def latest(self, booking_id: str) -> LocationSnapshot | None: ...

    async def set_gate(self, gate: BookingGate) -> None: ...

    async def get_gate(self, booking_id: str) -> BookingGate | None: ...
