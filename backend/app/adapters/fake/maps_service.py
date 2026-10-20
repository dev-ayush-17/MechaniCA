from app.domain.errors import NotFound
from app.domain.maps import GeoPoint, RouteSummary

# Deterministic Patna stand-in so tests and the demo work without a Maps key.
PATNA = GeoPoint(lat=25.5941, lng=85.1376)
_FAKE_ROUTE = RouteSummary(
    distance_m=4200,
    duration_s=720,
    encoded_polyline="w}iiD}{qvM",
)


class FakeMapsService:
    async def geocode(self, address: str) -> GeoPoint:
        if not address.strip():
            raise NotFound("We could not find that address.")
        return PATNA

    async def reverse_geocode(self, lat: float, lng: float) -> str:
        return "Boring Road, Patna"

    async def route(
        self, origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float
    ) -> RouteSummary:
        return _FAKE_ROUTE
