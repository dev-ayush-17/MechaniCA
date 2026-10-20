from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from app.domain.audit import AuditEvent
from app.domain.booking import Booking
from app.domain.booking_state import BookingStatus
from app.domain.dispute import Dispute
from app.domain.errors import PermissionDenied
from app.domain.mechanic import Mechanic, MechanicDocument
from app.domain.payment import ONLINE_METHODS, PaymentReason, PaymentStatus
from app.domain.user import Principal, Role, User
from app.ports.analytics_service import AnalyticsService
from app.ports.audit_log import AuditLog
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.dispute_repository import DisputeRepository
from app.ports.mechanic_repository import MechanicRepository
from app.ports.payment_repository import PaymentRepository
from app.ports.user_repository import UserRepository

_STAFF = frozenset({Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN})
_ADMIN = frozenset({Role.ADMIN, Role.SUPER_ADMIN})
_IST = ZoneInfo("Asia/Kolkata")
_PAID_LIKE = frozenset(
    {PaymentStatus.PAID, PaymentStatus.REFUNDED, PaymentStatus.PARTIALLY_REFUNDED}
)


def require_staff(principal: Principal) -> None:
    if principal.role not in _STAFF:
        raise PermissionDenied("Staff access required.")


def require_admin(principal: Principal) -> None:
    if principal.role not in _ADMIN:
        raise PermissionDenied("Admin access required.")


def window_start(now: datetime, window: str) -> datetime:
    local = now.astimezone(_IST)
    start = local.replace(hour=0, minute=0, second=0, microsecond=0)
    if window == "7d":
        start -= timedelta(days=6)
    elif window == "30d":
        start -= timedelta(days=29)
    return start.astimezone(UTC)


@dataclass(frozen=True)
class RevenueReport:
    gmv_paise: int
    refunds_paise: int
    cash_paise: int
    online_paise: int
    job_count: int


@dataclass(frozen=True)
class AdminQueries:
    users: UserRepository
    bookings: BookingRepository
    payments: PaymentRepository
    mechanics: MechanicRepository
    disputes: DisputeRepository
    audit: AuditLog
    analytics: AnalyticsService
    clock: Clock

    async def search_users(self, principal: Principal, query: str) -> list[User]:
        require_staff(principal)
        return await self.users.search(query)

    async def list_bookings(
        self,
        principal: Principal,
        *,
        status: str | None,
        city: str | None,
        date_from: datetime | None,
        date_to: datetime | None,
    ) -> list[Booking]:
        require_staff(principal)
        items = await self.bookings.list_all()
        if status:
            wanted = BookingStatus(status)
            items = [b for b in items if b.status is wanted]
        if city:
            needle = city.strip().lower()
            items = [b for b in items if b.address.city.lower() == needle]
        if date_from is not None:
            items = [b for b in items if b.created_at >= date_from]
        if date_to is not None:
            items = [b for b in items if b.created_at <= date_to]
        return items

    async def list_pending_applications(self, principal: Principal) -> list[Mechanic]:
        require_staff(principal)
        return await self.mechanics.list_pending()

    async def list_documents(
        self, principal: Principal, mechanic_id: str
    ) -> list[MechanicDocument]:
        require_staff(principal)
        return await self.mechanics.list_documents(mechanic_id)

    async def revenue(self, principal: Principal, window: str) -> RevenueReport:
        require_staff(principal)
        start = window_start(self.clock.now(), window)
        rows = [
            p
            for p in await self.payments.list_all()
            if p.reason is PaymentReason.BOOKING
            and p.status in _PAID_LIKE
            and p.created_at >= start
        ]
        cash = sum(p.amount_paise for p in rows if p.method.value == "cash")
        online = sum(p.amount_paise for p in rows if p.method in ONLINE_METHODS)
        return RevenueReport(
            gmv_paise=sum(p.amount_paise for p in rows),
            refunds_paise=sum(p.refunded_paise for p in rows),
            cash_paise=cash,
            online_paise=online,
            job_count=len(rows),
        )

    async def list_open_disputes(self, principal: Principal) -> list[Dispute]:
        require_staff(principal)
        return await self.disputes.list_open()

    async def list_audit(self, principal: Principal) -> list[AuditEvent]:
        require_admin(principal)
        return list(await self.audit.list_recent())

    async def analytics_counts(self, principal: Principal, days: int) -> dict[str, int]:
        require_staff(principal)
        start = self.clock.now() - timedelta(days=days)
        return self.analytics.counts_since(start)
