"""Booking and line-item value objects. Money fields are integer paise."""

from dataclasses import dataclass, replace
from datetime import datetime
from enum import StrEnum

from app.domain.booking_state import BookingStatus


class BookingMode(StrEnum):
    INSTANT = "instant"
    SCHEDULED = "scheduled"


class Urgency(StrEnum):
    NORMAL = "normal"
    SOS = "sos"


class PaymentMethod(StrEnum):
    UPI = "upi"
    CARD = "card"
    NETBANKING = "netbanking"
    CASH = "cash"
    WALLET = "wallet"


class LineKind(StrEnum):
    LABOR = "labor"
    PART = "part"
    FEE = "fee"


class LineStatus(StrEnum):
    INCLUDED = "included"
    PENDING_APPROVAL = "pending_approval"
    APPROVED = "approved"
    REJECTED = "rejected"


@dataclass(frozen=True)
class BookingPolicy:
    """Tunable booking rules. Bound from Settings in deps.py, not read from env here."""

    auto_confirm: bool = True
    cancel_fee_enroute_paise: int = 9900
    service_area_lat: float = 25.5941
    service_area_lng: float = 85.1376
    service_area_radius_km: float = 50.0
    scheduled_min_lead_minutes: int = 90
    scheduled_max_days: int = 7
    idempotency_ttl_hours: int = 24


@dataclass(frozen=True)
class AddressSnapshot:
    id: str
    label: str
    line1: str
    city: str
    pincode: str
    lat: float
    lng: float


@dataclass(frozen=True)
class BookingLine:
    id: str
    kind: LineKind
    name: str
    amount_paise: int
    gst_paise: int
    status: LineStatus
    part_replacement: bool = False


@dataclass(frozen=True)
class Booking:
    id: str
    display_number: str
    customer_id: str
    vehicle_id: str
    service_code: str
    service_name: str
    mode: BookingMode
    urgency: Urgency
    status: BookingStatus
    payment_method: PaymentMethod
    address: AddressSnapshot
    labor_paise: int
    parts_paise: int
    fee_paise: int
    discount_paise: int
    cgst_paise: int
    sgst_paise: int
    total_paise: int
    cancel_fee_paise: int
    cancel_reason: str | None
    scheduled_start: datetime | None
    mechanic_id: str | None
    lines: tuple[BookingLine, ...]
    created_at: datetime
    updated_at: datetime
    version: int

    def with_status(
        self,
        status: BookingStatus,
        *,
        now: datetime,
        mechanic_id: str | None = None,
        cancel_fee_paise: int | None = None,
        cancel_reason: str | None = None,
    ) -> "Booking":
        return replace(
            self,
            status=status,
            mechanic_id=self.mechanic_id if mechanic_id is None else mechanic_id,
            cancel_fee_paise=self.cancel_fee_paise
            if cancel_fee_paise is None
            else cancel_fee_paise,
            cancel_reason=self.cancel_reason if cancel_reason is None else cancel_reason,
            updated_at=now,
            version=self.version + 1,
        )

    def with_lines(self, lines: tuple[BookingLine, ...], *, now: datetime) -> "Booking":
        return replace(self, lines=lines, updated_at=now, version=self.version + 1)
