"""Coupon rules. Validate does not consume; redeem does, once per booking."""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class CouponType(StrEnum):
    FLAT = "flat"
    PERCENT = "percent"


@dataclass(frozen=True)
class Coupon:
    code: str
    type: CouponType
    amount: int
    max_discount_paise: int
    min_labor_paise: int
    starts_at: datetime
    ends_at: datetime
    max_redemptions: int
    per_user_limit: int
    first_booking_only: bool
    active: bool
    title: str
    description: str


@dataclass(frozen=True)
class CouponContext:
    user_id: str
    labor_paise: int
    prior_booking_count: int = 0


@dataclass(frozen=True)
class CouponQuote:
    code: str
    discount_paise: int
    message: str


@dataclass(frozen=True)
class CouponRedemption:
    coupon_code: str
    user_id: str
    booking_id: str
    amount_paise: int
    created_at: datetime
