from datetime import UTC, datetime, timedelta

from app.domain.geo import haversine_km
from app.domain.location import LocationPoint, accept_point, is_stale, last_seen_label

NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
PATNA = (25.5941, 85.1376)


def _point(lat: float, lng: float, at: datetime, speed_mps: float | None = None) -> LocationPoint:
    return LocationPoint(
        lat=lat, lng=lng, accuracy_m=20.0, recorded_at=at, speed_mps=speed_mps
    )


def test_stale_after_60_seconds() -> None:
    point = _point(*PATNA, NOW)
    assert is_stale(point, NOW + timedelta(seconds=60)) is False
    assert is_stale(point, NOW + timedelta(seconds=61)) is True
    assert last_seen_label(point, NOW + timedelta(minutes=3)).startswith("Last seen")


def test_jump_over_2km_dropped() -> None:
    first = _point(*PATNA, NOW)
    # About 5 km east of the first point, 5 seconds later.
    jumped_lng = PATNA[1] + 5.0 / (111.32 * 0.902)
    jumped = _point(PATNA[0], jumped_lng, NOW + timedelta(seconds=5))
    assert haversine_km(first.lat, first.lng, jumped.lat, jumped.lng) > 2.0
    assert accept_point(first, jumped) is None
    later = _point(PATNA[0], jumped_lng, NOW + timedelta(seconds=6))
    assert accept_point(first, later) is not None
