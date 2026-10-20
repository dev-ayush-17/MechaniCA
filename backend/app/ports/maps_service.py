from typing import Protocol

from app.domain.maps import GeoPoint, RouteSummary


class MapsService(Protocol):
    async def geocode(self, address: str) -> GeoPoint: ...

    async def reverse_geocode(self, lat: float, lng: float) -> str: ...

    async def route(
        self, origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float
    ) -> RouteSummary: ...
