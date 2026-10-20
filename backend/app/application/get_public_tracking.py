from dataclasses import dataclass

from app.domain.booking_state import BookingStatus
from app.domain.errors import NotFound, Unavailable
from app.domain.location import LocationPoint
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.location_tracking import LocationTrackingService
from app.ports.maps_service import MapsService
from app.ports.mechanic_repository import MechanicRepository
from app.ports.tracking_link_store import TrackingLinkStore
from app.ports.vehicle_repository import VehicleRepository

_ENDED = frozenset({BookingStatus.PAID, BookingStatus.CANCELLED, BookingStatus.FAILED})


@dataclass(frozen=True)
class PublicTracking:
    mechanic_first_name: str
    vehicle_label: str
    status: str
    eta_seconds: int | None
    mechanic_lat: float | None
    mechanic_lng: float | None
    dest_lat: float
    dest_lng: float


@dataclass(frozen=True)
class GetPublicTracking:
    links: TrackingLinkStore
    bookings: BookingRepository
    locations: LocationTrackingService
    maps: MapsService
    mechanics: MechanicRepository
    vehicles: VehicleRepository
    clock: Clock

    async def execute(self, token: str) -> PublicTracking:
        link = await self.links.get(token)
        if link is None or link.expires_at <= self.clock.now():
            raise NotFound("This tracking link has ended.")
        booking = await self.bookings.get(link.booking_id)
        if booking is None or booking.status in _ENDED:
            raise NotFound("This tracking link has ended.")
        snapshot = await self.locations.latest(booking.id)
        mechanic_point = snapshot.mechanic if snapshot else None
        return PublicTracking(
            mechanic_first_name=await self._mechanic_first_name(booking.mechanic_id),
            vehicle_label=await self._vehicle_label(booking.vehicle_id, booking.customer_id),
            status=booking.status.value,
            eta_seconds=await self._eta(mechanic_point, booking.address.lat, booking.address.lng),
            mechanic_lat=mechanic_point.lat if mechanic_point else None,
            mechanic_lng=mechanic_point.lng if mechanic_point else None,
            dest_lat=booking.address.lat,
            dest_lng=booking.address.lng,
        )

    async def _mechanic_first_name(self, mechanic_id: str | None) -> str:
        if not mechanic_id:
            return "Mechanic"
        mechanic = await self.mechanics.get(mechanic_id)
        if mechanic is None or not mechanic.display_name.strip():
            return "Mechanic"
        return mechanic.display_name.strip().split()[0]

    async def _vehicle_label(self, vehicle_id: str, owner_id: str) -> str:
        vehicle = await self.vehicles.get(vehicle_id, owner_id)
        if vehicle is None:
            return "Vehicle"
        return f"{vehicle.brand} {vehicle.model}".strip() or "Vehicle"

    async def _eta(
        self, point: LocationPoint | None, dest_lat: float, dest_lng: float
    ) -> int | None:
        if point is None:
            return None
        try:
            summary = await self.maps.route(point.lat, point.lng, dest_lat, dest_lng)
        except (Unavailable, NotFound):
            return None
        return summary.duration_s
