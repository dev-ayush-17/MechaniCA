from dataclasses import dataclass, replace
from datetime import datetime
from uuid import uuid4

from app.domain.audit import AuditEvent
from app.domain.coupon import Coupon, CouponType
from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.user import Principal, Role
from app.ports.audit_log import AuditLog
from app.ports.clock import Clock
from app.ports.coupon_service import CouponService


@dataclass(frozen=True)
class CouponView:
    coupon: Coupon
    redemption_count: int


@dataclass(frozen=True)
class AdminCoupons:
    coupons: CouponService
    audit: AuditLog
    clock: Clock

    def _require_admin(self, principal: Principal) -> None:
        if principal.role not in {Role.ADMIN, Role.SUPER_ADMIN}:
            raise PermissionDenied("Admin access required.")

    async def list_all(self, principal: Principal) -> list[CouponView]:
        if principal.role not in {Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN}:
            raise PermissionDenied("Staff access required.")
        items = await self.coupons.list_all()
        return [
            CouponView(coupon=c, redemption_count=await self.coupons.redemption_count(c.code))
            for c in items
        ]

    async def create(
        self,
        principal: Principal,
        *,
        code: str,
        coupon_type: CouponType,
        amount: int,
        title: str,
        description: str,
        max_discount_paise: int,
        min_labor_paise: int,
        starts_at: datetime,
        ends_at: datetime,
        max_redemptions: int,
        per_user_limit: int,
        first_booking_only: bool,
        request_id: str,
    ) -> CouponView:
        self._require_admin(principal)
        cleaned = code.strip().upper()
        if not cleaned:
            raise InvalidInput("Add a code.", fields={"code": "required"})
        if amount <= 0:
            raise InvalidInput("Amount must be greater than zero.")
        coupon = await self.coupons.create(
            Coupon(
                code=cleaned,
                type=coupon_type,
                amount=amount,
                max_discount_paise=max_discount_paise,
                min_labor_paise=min_labor_paise,
                starts_at=starts_at,
                ends_at=ends_at,
                max_redemptions=max_redemptions,
                per_user_limit=per_user_limit,
                first_booking_only=first_booking_only,
                active=True,
                title=title,
                description=description,
            )
        )
        await self._audit(principal, "coupon_create", coupon.code, request_id)
        return CouponView(coupon=coupon, redemption_count=0)

    async def update(
        self,
        principal: Principal,
        code: str,
        *,
        title: str | None,
        amount: int | None,
        request_id: str,
    ) -> CouponView:
        self._require_admin(principal)
        current = await self.coupons.get(code)
        if current is None:
            raise NotFound("We could not find that coupon.")
        updated = await self.coupons.update(
            replace(
                current,
                title=title if title is not None else current.title,
                amount=amount if amount is not None else current.amount,
            )
        )
        await self._audit(principal, "coupon_update", updated.code, request_id)
        return CouponView(
            coupon=updated, redemption_count=await self.coupons.redemption_count(updated.code)
        )

    async def disable(self, principal: Principal, code: str, *, request_id: str) -> CouponView:
        self._require_admin(principal)
        coupon = await self.coupons.disable(code)
        await self._audit(principal, "coupon_disable", coupon.code, request_id)
        return CouponView(
            coupon=coupon, redemption_count=await self.coupons.redemption_count(coupon.code)
        )

    async def _audit(
        self, principal: Principal, action: str, target_id: str, request_id: str
    ) -> None:
        await self.audit.append(
            AuditEvent(
                id=uuid4().hex,
                actor_id=principal.user_id,
                role=principal.role.value,
                action=action,
                target_type="coupon",
                target_id=target_id,
                summary=action,
                request_id=request_id,
                created_at=self.clock.now(),
            )
        )
