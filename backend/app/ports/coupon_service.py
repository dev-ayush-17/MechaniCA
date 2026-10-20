from typing import Protocol

from app.domain.coupon import Coupon, CouponContext, CouponQuote


class CouponService(Protocol):
    """Validate does not increment counters. Redeem does, once per booking."""

    async def get(self, code: str) -> Coupon | None: ...

    async def list_active(self) -> list[Coupon]: ...

    async def validate(self, code: str, context: CouponContext) -> CouponQuote: ...

    async def redeem(self, code: str, booking_id: str, context: CouponContext) -> CouponQuote: ...
