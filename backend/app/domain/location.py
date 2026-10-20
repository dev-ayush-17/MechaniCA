"""Live location points, jump filter, and staleness (FR-TRK-006, FR-TRK-007)."""

from dataclasses import dataclass
from datetime import datetime, timedelta

from app.domain.geo import haversine_km

STALE_AFTER = timedelta(seconds=60)
JUMP_MAX_KM = 2.0
JUMP_WINDOW = timedelta(seconds=5)
GEOFENCE_M = 150.0
DUTY_FAST = timedelta(seconds=5)
DUTY_SLOW = timedelta(seconds=15)
ARRIVED_PUBLISH_FOR = timedelta(minutes=2)
SPEED_FAST_KMH = 5.0
ACCURACY_TARGET_M = 50.0
TROUBLE_AFTER = timedelta(minutes=5)
LOCATION_OPEN_STATUSES = frozenset({"mechanicAssigned", "enRoute", "arrived"})
TERMINAL_FOR_TOKEN = frozenset({"paid", "cancelled", "failed"})


@dataclass(frozen=True)
class LocationPoint:
    lat: float
    lng: float
    accuracy_m: float
    recorded_at: datetime
    speed_mps: float | None = None


@dataclass(frozen=True)
class LocationSnapshot:
    mechanic: LocationPoint | None = None
    customer: LocationPoint | None = None


@dataclass(frozen=True)
class BookingGate:
    booking_id: str
    customer_id: str
    mechanic_id: str | None
    location_open: bool


def is_stale(point: LocationPoint, now: datetime, *, threshold: timedelta = STALE_AFTER) -> bool:
    return now - point.recorded_at > threshold


def last_seen_label(point: LocationPoint, now: datetime) -> str:
    minutes = max(1, int((now - point.recorded_at).total_seconds() // 60))
    return f"Last seen {minutes} min ago."


def accept_point(previous: LocationPoint | None, candidate: LocationPoint) -> LocationPoint | None:
    """Drop GPS drift: more than 2 km in 5 seconds is not shown or stored."""
    if previous is None:
        return candidate
    elapsed = candidate.recorded_at - previous.recorded_at
    if elapsed <= timedelta(0):
        return None
    distance_km = haversine_km(previous.lat, previous.lng, candidate.lat, candidate.lng)
    if distance_km > JUMP_MAX_KM and elapsed <= JUMP_WINDOW:
        return None
    return candidate


def within_geofence(
    mechanic: LocationPoint, dest_lat: float, dest_lng: float, *, radius_m: float = GEOFENCE_M
) -> bool:
    return haversine_km(mechanic.lat, mechanic.lng, dest_lat, dest_lng) * 1000 <= radius_m


def duty_interval(status: str, speed_mps: float | None) -> timedelta | None:
    """None means stop publishing. Fast cycle only while enRoute and moving."""
    if status not in LOCATION_OPEN_STATUSES:
        return None
    speed_kmh = (speed_mps or 0.0) * 3.6
    if status == "enRoute" and speed_kmh > SPEED_FAST_KMH:
        return DUTY_FAST
    return DUTY_SLOW


def still_publishing_after_arrived(arrived_at: datetime, now: datetime) -> bool:
    return now - arrived_at < ARRIVED_PUBLISH_FOR
