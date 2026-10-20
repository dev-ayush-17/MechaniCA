from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Header, Query, Request
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import (
    add_dispute_note_dep,
    admin_coupons_dep,
    admin_principal_dep,
    admin_queries_dep,
    resolve_dispute_dep,
    staff_principal_dep,
    suspend_user_dep,
)
from app.api.errors import REQUEST_ID_HEADER, error_responses
from app.api.v1.mechanic import MechanicOut
from app.application.admin_coupons import AdminCoupons, CouponView
from app.application.admin_queries import AdminQueries, RevenueReport
from app.application.disputes import AddDisputeNote, ResolveDispute
from app.application.suspend_user import SuspendUser
from app.domain.booking import Booking
from app.domain.coupon import CouponType
from app.domain.dispute import Dispute, DisputeResolution
from app.domain.user import Principal, User

router = APIRouter(
    prefix="/v1/admin",
    tags=["admin"],
    responses=error_responses(400, 401, 403, 404, 409),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class SuspensionRequest(_Camel):
    reason: str


class AdminUserOut(_Camel):
    id: str
    name: str
    phone_e164: str
    role: str
    status: str

    @classmethod
    def of(cls, user: User) -> "AdminUserOut":
        return cls(
            id=user.id,
            name=user.name,
            phone_e164=user.phone_e164,
            role=user.role.value,
            status=user.status.value,
        )


class AdminUserListOut(_Camel):
    items: list[AdminUserOut]


class AdminBookingOut(_Camel):
    id: str
    display_number: str
    status: str
    city: str
    created_at: datetime
    total_paise: int
    customer_id: str

    @classmethod
    def of(cls, booking: Booking) -> "AdminBookingOut":
        return cls(
            id=booking.id,
            display_number=booking.display_number,
            status=booking.status.value,
            city=booking.address.city,
            created_at=booking.created_at,
            total_paise=booking.total_paise,
            customer_id=booking.customer_id,
        )


class AdminBookingListOut(_Camel):
    items: list[AdminBookingOut]


class MechanicListOut(_Camel):
    items: list[MechanicOut]


class DocumentOut(_Camel):
    id: str
    kind: str
    storage_path: str


class DocumentListOut(_Camel):
    items: list[DocumentOut]


class RevenueOut(_Camel):
    gmv_paise: int
    refunds_paise: int
    cash_paise: int
    online_paise: int
    job_count: int

    @classmethod
    def of(cls, report: RevenueReport) -> "RevenueOut":
        return cls(
            gmv_paise=report.gmv_paise,
            refunds_paise=report.refunds_paise,
            cash_paise=report.cash_paise,
            online_paise=report.online_paise,
            job_count=report.job_count,
        )


class AdminCouponOut(_Camel):
    code: str
    type: str
    amount: int
    title: str
    description: str
    active: bool
    redemption_count: int
    max_redemptions: int
    min_labor_paise: int
    starts_at: datetime
    ends_at: datetime

    @classmethod
    def of(cls, view: CouponView) -> "AdminCouponOut":
        coupon = view.coupon
        return cls(
            code=coupon.code,
            type=coupon.type.value,
            amount=coupon.amount,
            title=coupon.title,
            description=coupon.description,
            active=coupon.active,
            redemption_count=view.redemption_count,
            max_redemptions=coupon.max_redemptions,
            min_labor_paise=coupon.min_labor_paise,
            starts_at=coupon.starts_at,
            ends_at=coupon.ends_at,
        )


class AdminCouponListOut(_Camel):
    items: list[AdminCouponOut]


class CreateCouponRequest(_Camel):
    code: str
    type: CouponType
    amount: int
    title: str
    description: str = ""
    max_discount_paise: int = 0
    min_labor_paise: int = 0
    starts_at: datetime
    ends_at: datetime
    max_redemptions: int = 1000
    per_user_limit: int = 1
    first_booking_only: bool = False


class PatchCouponRequest(_Camel):
    title: str | None = None
    amount: int | None = None


class DisputeNoteOut(_Camel):
    actor_id: str
    body: str
    created_at: datetime


class DisputeOut(_Camel):
    id: str
    booking_id: str
    customer_id: str
    reason: str
    status: str
    notes: list[DisputeNoteOut]
    resolution: str | None
    resolution_amount_paise: int
    resolution_note: str
    created_at: datetime

    @classmethod
    def of(cls, dispute: Dispute) -> "DisputeOut":
        return cls(
            id=dispute.id,
            booking_id=dispute.booking_id,
            customer_id=dispute.customer_id,
            reason=dispute.reason,
            status=dispute.status.value,
            notes=[
                DisputeNoteOut(actor_id=n.actor_id, body=n.body, created_at=n.created_at)
                for n in dispute.notes
            ],
            resolution=dispute.resolution.value if dispute.resolution else None,
            resolution_amount_paise=dispute.resolution_amount_paise,
            resolution_note=dispute.resolution_note,
            created_at=dispute.created_at,
        )


class DisputeListOut(_Camel):
    items: list[DisputeOut]


class DisputeNoteRequest(_Camel):
    note: str


class ResolveDisputeRequest(_Camel):
    resolution: DisputeResolution
    amount_paise: int = 0
    note: str


class AuditEventOut(_Camel):
    id: str
    actor_id: str
    role: str
    action: str
    target_type: str
    target_id: str
    summary: str
    request_id: str
    created_at: datetime


class AuditListOut(_Camel):
    items: list[AuditEventOut]


class AnalyticsOut(_Camel):
    counts: dict[str, int]


def _request_id(request: Request) -> str:
    return request.headers.get(REQUEST_ID_HEADER, getattr(request.state, "request_id", ""))


@router.get("/users", response_model=AdminUserListOut)
async def search_users(
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    queries: Annotated[AdminQueries, Depends(admin_queries_dep)],
    q: str = "",
) -> AdminUserListOut:
    items = await queries.search_users(principal, q)
    return AdminUserListOut(items=[AdminUserOut.of(user) for user in items])


@router.post("/users/{user_id}/suspension", response_model=AdminUserOut)
async def suspend_user(
    user_id: str,
    body: SuspensionRequest,
    request: Request,
    principal: Annotated[Principal, Depends(admin_principal_dep)],
    use_case: Annotated[SuspendUser, Depends(suspend_user_dep)],
) -> AdminUserOut:
    user = await use_case.execute(
        principal, user_id, reason=body.reason, request_id=_request_id(request)
    )
    return AdminUserOut.of(user)


@router.get("/applications", response_model=MechanicListOut)
async def list_applications(
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    queries: Annotated[AdminQueries, Depends(admin_queries_dep)],
) -> MechanicListOut:
    items = await queries.list_pending_applications(principal)
    return MechanicListOut(items=[MechanicOut.of(item) for item in items])


@router.get("/applications/{mechanic_id}/documents", response_model=DocumentListOut)
async def list_application_documents(
    mechanic_id: str,
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    queries: Annotated[AdminQueries, Depends(admin_queries_dep)],
) -> DocumentListOut:
    docs = await queries.list_documents(principal, mechanic_id)
    return DocumentListOut(
        items=[DocumentOut(id=d.id, kind=d.kind.value, storage_path=d.storage_path) for d in docs]
    )


@router.get("/bookings", response_model=AdminBookingListOut)
async def list_admin_bookings(
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    queries: Annotated[AdminQueries, Depends(admin_queries_dep)],
    status: str | None = None,
    city: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
) -> AdminBookingListOut:
    items = await queries.list_bookings(
        principal, status=status, city=city, date_from=date_from, date_to=date_to
    )
    return AdminBookingListOut(items=[AdminBookingOut.of(item) for item in items])


@router.get("/revenue", response_model=RevenueOut)
async def get_revenue(
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    queries: Annotated[AdminQueries, Depends(admin_queries_dep)],
    window: Literal["today", "7d", "30d"] = "today",
) -> RevenueOut:
    return RevenueOut.of(await queries.revenue(principal, window))


@router.get("/coupons", response_model=AdminCouponListOut)
async def list_admin_coupons(
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    use_case: Annotated[AdminCoupons, Depends(admin_coupons_dep)],
) -> AdminCouponListOut:
    items = await use_case.list_all(principal)
    return AdminCouponListOut(items=[AdminCouponOut.of(item) for item in items])


@router.post("/coupons", response_model=AdminCouponOut, status_code=201)
async def create_coupon(
    body: CreateCouponRequest,
    request: Request,
    principal: Annotated[Principal, Depends(admin_principal_dep)],
    use_case: Annotated[AdminCoupons, Depends(admin_coupons_dep)],
) -> AdminCouponOut:
    view = await use_case.create(
        principal,
        code=body.code,
        coupon_type=body.type,
        amount=body.amount,
        title=body.title,
        description=body.description,
        max_discount_paise=body.max_discount_paise,
        min_labor_paise=body.min_labor_paise,
        starts_at=body.starts_at,
        ends_at=body.ends_at,
        max_redemptions=body.max_redemptions,
        per_user_limit=body.per_user_limit,
        first_booking_only=body.first_booking_only,
        request_id=_request_id(request),
    )
    return AdminCouponOut.of(view)


@router.patch("/coupons/{code}", response_model=AdminCouponOut)
async def patch_coupon(
    code: str,
    body: PatchCouponRequest,
    request: Request,
    principal: Annotated[Principal, Depends(admin_principal_dep)],
    use_case: Annotated[AdminCoupons, Depends(admin_coupons_dep)],
) -> AdminCouponOut:
    view = await use_case.update(
        principal,
        code,
        title=body.title,
        amount=body.amount,
        request_id=_request_id(request),
    )
    return AdminCouponOut.of(view)


@router.post("/coupons/{code}/disable", response_model=AdminCouponOut)
async def disable_coupon(
    code: str,
    request: Request,
    principal: Annotated[Principal, Depends(admin_principal_dep)],
    use_case: Annotated[AdminCoupons, Depends(admin_coupons_dep)],
) -> AdminCouponOut:
    return AdminCouponOut.of(
        await use_case.disable(principal, code, request_id=_request_id(request))
    )


@router.get("/disputes", response_model=DisputeListOut)
async def list_disputes(
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    queries: Annotated[AdminQueries, Depends(admin_queries_dep)],
) -> DisputeListOut:
    items = await queries.list_open_disputes(principal)
    return DisputeListOut(items=[DisputeOut.of(item) for item in items])


@router.post("/disputes/{dispute_id}/notes", response_model=DisputeOut)
async def add_dispute_note(
    dispute_id: str,
    body: DisputeNoteRequest,
    request: Request,
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    use_case: Annotated[AddDisputeNote, Depends(add_dispute_note_dep)],
) -> DisputeOut:
    return DisputeOut.of(
        await use_case.execute(
            principal, dispute_id, note=body.note, request_id=_request_id(request)
        )
    )


@router.post("/disputes/{dispute_id}/resolve", response_model=DisputeOut)
async def resolve_dispute(
    dispute_id: str,
    body: ResolveDisputeRequest,
    request: Request,
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    use_case: Annotated[ResolveDispute, Depends(resolve_dispute_dep)],
    idempotency_key: Annotated[str | None, Header()] = None,
) -> DisputeOut:
    return DisputeOut.of(
        await use_case.execute(
            principal,
            dispute_id,
            resolution=body.resolution,
            amount_paise=body.amount_paise,
            note=body.note,
            request_id=_request_id(request),
            idempotency_key=idempotency_key,
        )
    )


@router.get("/audit", response_model=AuditListOut)
async def list_audit(
    principal: Annotated[Principal, Depends(admin_principal_dep)],
    queries: Annotated[AdminQueries, Depends(admin_queries_dep)],
) -> AuditListOut:
    events = await queries.list_audit(principal)
    return AuditListOut(
        items=[
            AuditEventOut(
                id=e.id,
                actor_id=e.actor_id,
                role=e.role,
                action=e.action,
                target_type=e.target_type,
                target_id=e.target_id,
                summary=e.summary,
                request_id=e.request_id,
                created_at=e.created_at,
            )
            for e in events
        ]
    )


@router.get("/analytics", response_model=AnalyticsOut)
async def get_analytics(
    principal: Annotated[Principal, Depends(staff_principal_dep)],
    queries: Annotated[AdminQueries, Depends(admin_queries_dep)],
    days: Annotated[int, Query(ge=1, le=90)] = 7,
) -> AnalyticsOut:
    return AnalyticsOut(counts=await queries.analytics_counts(principal, days))
