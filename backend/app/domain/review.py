"""Customer reviews of a mechanic. Aggregates are recomputed on the server."""

import re
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

_PHONE = re.compile(r"(?:\+91[\s-]*)?[6-9]\d{9}|\b\d{10}\b")


class ReviewStatus(StrEnum):
    PENDING = "pending"
    PUBLISHED = "published"
    HIDDEN = "hidden"
    REJECTED = "rejected"


@dataclass(frozen=True)
class RatingAggregate:
    rating_avg: float
    rating_count: int


@dataclass(frozen=True)
class Review:
    id: str
    booking_id: str
    customer_id: str
    mechanic_id: str
    stars: int
    text: str
    photo_paths: tuple[str, ...]
    status: ReviewStatus
    created_at: datetime
    updated_at: datetime
    version: int


def classify_review_text(text: str, blocked_words: tuple[str, ...]) -> ReviewStatus:
    """Empty text publishes immediately. Phone numbers and blocked words are rejected."""
    stripped = text.strip()
    if not stripped:
        return ReviewStatus.PUBLISHED
    if _PHONE.search(stripped):
        return ReviewStatus.REJECTED
    lowered = stripped.lower()
    if any(word and word.lower() in lowered for word in blocked_words):
        return ReviewStatus.REJECTED
    return ReviewStatus.PUBLISHED


def average_to_one_decimal(total_stars: int, count: int) -> float:
    if count <= 0:
        return 0.0
    return round(total_stars / count, 1)
