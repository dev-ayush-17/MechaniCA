"""Wallet ledger. Balance is the sum of entries, never a client-written field."""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class LedgerDirection(StrEnum):
    CREDIT = "credit"
    DEBIT = "debit"


class LedgerReason(StrEnum):
    TOPUP = "topup"
    BOOKING_PAYMENT = "booking_payment"
    REFUND = "refund"
    CANCEL_FEE = "cancel_fee"
    ADJUSTMENT = "adjustment"


@dataclass(frozen=True)
class Money:
    paise: int


@dataclass(frozen=True)
class LedgerEntry:
    id: str
    user_id: str
    booking_id: str | None
    direction: LedgerDirection
    amount_paise: int
    reason: LedgerReason
    created_at: datetime
