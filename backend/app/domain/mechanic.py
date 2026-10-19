from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class VerificationStatus(StrEnum):
    DRAFT = "draft"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class DocumentKind(StrEnum):
    LICENCE = "licence"
    GOVERNMENT_ID = "government_id"
    SELFIE = "selfie"


@dataclass(frozen=True)
class ServiceArea:
    lat: float
    lng: float
    radius_km: float
    geohash: str


@dataclass(frozen=True)
class MechanicDocument:
    id: str
    mechanic_id: str
    kind: DocumentKind
    storage_path: str
    uploaded_at: datetime


@dataclass(frozen=True)
class Mechanic:
    id: str
    display_name: str
    photo_path: str
    years_experience: int
    languages: tuple[str, ...]
    service_area: ServiceArea | None
    verified: bool
    verification_status: VerificationStatus
    online: bool
    last_heartbeat_at: datetime | None
    rating_avg: float
    rating_count: int
    version: int
    rejection_reason: str | None = None
