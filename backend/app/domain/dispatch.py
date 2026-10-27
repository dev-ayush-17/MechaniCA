"""Sequential dispatch ranking and offer timings (docs/prd/14-dispatch.md, ADR-013)."""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

from app.domain.booking import Urgency


class OfferStatus(StrEnum):
    OPEN = "open"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    EXPIRED = "expired"


@dataclass(frozen=True)
class DispatchConfig:
    rating_weight: float = 20.0
    acceptance_weight: float = 30.0
    distance_weight: float = 8.0
    recent_offers_weight: float = 5.0
    default_rating: float = 4.5
    rating_floor_count: int = 5
    default_acceptance: float = 0.8
    acceptance_floor_count: int = 10
    recent_offers_minutes: int = 30
    acceptance_window_days: int = 30
    heartbeat_fresh_seconds: int = 120
    sos_close_km: float = 3.0
    sos_close_bonus: float = 15.0
    max_attempts: int = 3
    normal_ttl_seconds: int = 45
    sos_ttl_seconds: int = 20
    normal_radii_km: tuple[float, ...] = (5.0, 8.0, 12.0)
    sos_radii_km: tuple[float, ...] = (8.0, 15.0, 25.0)
    assigned_stale_seconds: int = 600
    extra_work_timeout_seconds: int = 600
    # 0 keeps the spec: nobody in range fails the booking immediately.
    # A local demo may wait so a mechanic can come online after submit.
    wait_for_mechanic_seconds: int = 0


@dataclass(frozen=True)
class Offer:
    id: str
    booking_id: str
    mechanic_id: str
    status: OfferStatus
    expires_at: datetime
    attempt: int
    score: float
    distance_km: float
    created_at: datetime


@dataclass(frozen=True)
class RankedCandidate:
    mechanic_id: str
    score: float
    distance_km: float


def offer_ttl_seconds(urgency: Urgency, config: DispatchConfig | None = None) -> int:
    cfg = config or DispatchConfig()
    return cfg.sos_ttl_seconds if urgency is Urgency.SOS else cfg.normal_ttl_seconds


def radii_km(urgency: Urgency, config: DispatchConfig | None = None) -> tuple[float, ...]:
    cfg = config or DispatchConfig()
    return cfg.sos_radii_km if urgency is Urgency.SOS else cfg.normal_radii_km


def effective_rating(rating_avg: float, rating_count: int, config: DispatchConfig) -> float:
    if rating_count < config.rating_floor_count:
        return config.default_rating
    return rating_avg


def acceptance_rate(accepts: int, rejects: int, timeouts: int, config: DispatchConfig) -> float:
    sample = accepts + rejects + timeouts
    if sample < config.acceptance_floor_count:
        return config.default_acceptance
    return accepts / sample


def score_candidate(
    *,
    rating_avg: float,
    rating_count: int,
    acceptance: float,
    distance_km: float,
    recent_offers: int,
    urgency: Urgency,
    config: DispatchConfig | None = None,
) -> float:
    """Higher is better. SOS inside 3 km ignores rating so closer wins."""
    cfg = config or DispatchConfig()
    close_sos = urgency is Urgency.SOS and distance_km <= cfg.sos_close_km
    rating = 0.0 if close_sos else effective_rating(rating_avg, rating_count, cfg)
    bonus = cfg.sos_close_bonus if close_sos else 0.0
    return (
        (rating * cfg.rating_weight)
        + (acceptance * cfg.acceptance_weight)
        - (distance_km * cfg.distance_weight)
        - (recent_offers * cfg.recent_offers_weight)
        + bonus
    )


def customer_dispatch_copy(*, status: str, attempt: int, urgency: Urgency) -> str:
    """Chapter 14 copy. The UI may duplicate these strings."""
    if status == "failed":
        if urgency is Urgency.SOS:
            return "No mechanic could take the priority request. If this is an emergency, call 112."
        return "No mechanic is free nearby. Try again or contact support."
    if status == "confirmed" and attempt > 1:
        return "Still looking. The first mechanic was unavailable."
    return "Finding a mechanic near you"
