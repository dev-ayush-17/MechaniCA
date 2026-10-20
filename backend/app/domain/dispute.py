from dataclasses import dataclass, replace
from datetime import datetime
from enum import StrEnum


class DisputeStatus(StrEnum):
    OPEN = "open"
    RESOLVED = "resolved"


class DisputeResolution(StrEnum):
    REFUND = "refund"
    NO_REFUND = "no_refund"
    CASH_WALLET_CREDIT = "cash_wallet_credit"


@dataclass(frozen=True)
class DisputeNote:
    actor_id: str
    body: str
    created_at: datetime


@dataclass(frozen=True)
class Dispute:
    id: str
    booking_id: str
    customer_id: str
    reason: str
    status: DisputeStatus
    notes: tuple[DisputeNote, ...]
    resolution: DisputeResolution | None
    resolution_amount_paise: int
    resolution_note: str
    created_at: datetime
    updated_at: datetime

    def with_note(self, note: DisputeNote, *, now: datetime) -> "Dispute":
        return replace(self, notes=(*self.notes, note), updated_at=now)

    def resolved(
        self,
        *,
        resolution: DisputeResolution,
        amount_paise: int,
        note: str,
        now: datetime,
    ) -> "Dispute":
        return replace(
            self,
            status=DisputeStatus.RESOLVED,
            resolution=resolution,
            resolution_amount_paise=amount_paise,
            resolution_note=note,
            updated_at=now,
        )
