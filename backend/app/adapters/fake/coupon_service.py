from datetime import UTC, datetime, timedelta

from app.domain.coupon import (
    Coupon,
    CouponContext,
    CouponQuote,
    CouponRedemption,
    CouponType,
)
from app.domain.errors import CouponRejected

_START = datetime(2026, 1, 1, tzinfo=UTC)
_END = datetime(2027, 1, 1, tzinfo=UTC)


def _seed() -> dict[str, Coupon]:
    return {
        "FLAT50": Coupon(
            code="FLAT50",
            type=CouponType.FLAT,
            amount=5000,
            max_discount_paise=5000,
            min_labor_paise=0,
            starts_at=_START,
            ends_at=_END,
            max_redemptions=1000,
            per_user_limit=5,
            first_booking_only=False,
            active=True,
            title="Flat ₹50 off",
            description="₹50 off labor",
        ),
        "ONCE": Coupon(
            code="ONCE",
            type=CouponType.FLAT,
            amount=1000,
            max_discount_paise=1000,
            min_labor_paise=0,
            starts_at=_START,
            ends_at=_END,
            max_redemptions=1,
            per_user_limit=1,
            first_booking_only=False,
            active=True,
            title="One redeem",
            description="Single use",
        ),
        "EXPIRED": Coupon(
            code="EXPIRED",
            type=CouponType.FLAT,
            amount=5000,
            max_discount_paise=5000,
            min_labor_paise=0,
            starts_at=_START,
            ends_at=_START + timedelta(days=1),
            max_redemptions=100,
            per_user_limit=1,
            first_booking_only=False,
            active=True,
            title="Expired",
            description="No longer valid",
        ),
        "MIN299": Coupon(
            code="MIN299",
            type=CouponType.PERCENT,
            amount=10,
            max_discount_paise=10000,
            min_labor_paise=29900,
            starts_at=_START,
            ends_at=_END,
            max_redemptions=100,
            per_user_limit=1,
            first_booking_only=False,
            active=True,
            title="10% off",
            description="Min labor ₹299",
        ),
    }


class FakeCouponService:
    def __init__(self, now: datetime | None = None) -> None:
        self.coupons = _seed()
        self.redemptions: list[CouponRedemption] = []
        self._now = now or datetime(2026, 6, 1, tzinfo=UTC)

    async def get(self, code: str) -> Coupon | None:
        return self.coupons.get(code.strip().upper())

    async def list_active(self) -> list[Coupon]:
        return [
            c for c in self.coupons.values() if c.active and c.starts_at <= self._now <= c.ends_at
        ]

    async def validate(self, code: str, context: CouponContext) -> CouponQuote:
        coupon = await self._usable(code, context, booking_id=None)
        discount = self._discount(coupon, context.labor_paise)
        return CouponQuote(code=coupon.code, discount_paise=discount, message="Coupon applied.")

    async def redeem(self, code: str, booking_id: str, context: CouponContext) -> CouponQuote:
        existing = next((r for r in self.redemptions if r.booking_id == booking_id), None)
        if existing is not None:
            return CouponQuote(
                code=existing.coupon_code,
                discount_paise=existing.amount_paise,
                message="Coupon applied.",
            )
        coupon = await self._usable(code, context, booking_id=booking_id)
        discount = self._discount(coupon, context.labor_paise)
        self.redemptions.append(
            CouponRedemption(
                coupon_code=coupon.code,
                user_id=context.user_id,
                booking_id=booking_id,
                amount_paise=discount,
                created_at=self._now,
            )
        )
        return CouponQuote(code=coupon.code, discount_paise=discount, message="Coupon applied.")

    async def _usable(self, code: str, context: CouponContext, *, booking_id: str | None) -> Coupon:
        coupon = await self.get(code)
        if coupon is None or not coupon.active:
            raise CouponRejected("Invalid coupon code")
        if self._now < coupon.starts_at or self._now > coupon.ends_at:
            raise CouponRejected("Code expired")
        if context.labor_paise < coupon.min_labor_paise:
            rupees = coupon.min_labor_paise // 100
            raise CouponRejected(f"Minimum labor is ₹{rupees}")
        if coupon.first_booking_only and context.prior_booking_count > 0:
            raise CouponRejected("Already used.")
        used = [r for r in self.redemptions if r.coupon_code == coupon.code]
        if booking_id is None or not any(r.booking_id == booking_id for r in used):
            if len(used) >= coupon.max_redemptions:
                raise CouponRejected("Already used.")
            user_used = [r for r in used if r.user_id == context.user_id]
            if len(user_used) >= coupon.per_user_limit:
                raise CouponRejected("Already used.")
        return coupon

    def _discount(self, coupon: Coupon, labor_paise: int) -> int:
        if coupon.type is CouponType.FLAT:
            raw = coupon.amount
        else:
            raw = labor_paise * coupon.amount // 100
        if coupon.max_discount_paise > 0:
            raw = min(raw, coupon.max_discount_paise)
        return min(raw, labor_paise)
