from dataclasses import dataclass


@dataclass(frozen=True)
class GeoPoint:
    lat: float
    lng: float


@dataclass(frozen=True)
class RouteSummary:
    distance_m: int
    duration_s: int
    encoded_polyline: str
