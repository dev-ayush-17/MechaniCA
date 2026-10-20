from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Header, Request
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

from app.api.deps import (
    apply_gateway_event_dep,
    confirm_cash_dep,
    coupon_service_dep,
    create_payment_dep,
    create_wallet_topup_dep,
    list_earnings_dep,
    mark_cash_collected_dep,
    payment_gateway_dep,
    payment_repository_dep,
    principal_dep,
    reconcile_pending_dep,
    refund_payment_dep,
    require_internal_job_dep,
    require_mechanic_dep,
    staff_confirm_cash_dep,
    wallet_service_dep,
)
from app.api.errors import error_responses
from app.application.apply_payment import ApplyGatewayEvent
from app.application.cash_confirm import ConfirmCash, MarkCashCollected, StaffConfirmCash
from app.application.create_payment import CreatePayment
from app.application.list_earnings import ListEarnings
from app.application.reconcile_payments import ReconcilePendingPayments
from app.application.refund_payment import RefundPayment
from app.application.wallet_topup import CreateWalletTopup
from app.domain.booking import PaymentMethod
from app.domain.coupon import Coupon, CouponContext
from app.domain.errors import NotFound
from app.domain.payment import Payment
from app.domain.user import Principal
from app.ports.coupon_service import CouponService
from app.ports.payment_gateway import PaymentGateway
from app.ports.payment_repository import PaymentRepository
from app.ports.wallet_service import WalletService

router = APIRouter(
    prefix="/v1/payments", tags=["payments"], responses=error_responses(400, 401, 403, 404, 409)
)
wallet_router = APIRouter(
    prefix="/v1/wallet", tags=["wallet"], responses=error_responses(400, 401, 403, 402)
)
coupons_router = APIRouter(
    prefix="/v1/coupons", tags=["coupons"], responses=error_responses(400, 401, 422)
)
admin_router = APIRouter(
    prefix="/v1/admin", tags=["admin"], responses=error_responses(400, 401, 403, 404, 409)
)
earnings_router = APIRouter(
    prefix="/v1/mechanic", tags=["mechanic"], responses=error_responses(401, 403)
)
internal_router = APIRouter(
    prefix="/v1/internal/jobs", tags=["internal"], responses=error_responses(401)
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class CreatePaymentRequest(_Camel):
    booking_id: str
    method: PaymentMethod


class CashDecisionRequest(_Camel):
    paid: bool = True


class StaffCashRequest(_Camel):
    note: str


class CashfreeSessionOut(_Camel):
    order_id: str
    payment_session_id: str


class PaymentOut(_Camel):
    payment_id: str
    status: str
    amount_paise: int
    method: str
    cashfree: CashfreeSessionOut | None = None

    @classmethod
    def of(cls, payment: Payment) -> "PaymentOut":
        session = None
        if payment.gateway_order_id and payment.payment_session_id:
            session = CashfreeSessionOut(
                order_id=payment.gateway_order_id,
                payment_session_id=payment.payment_session_id,
            )
        return cls(
            payment_id=payment.id,
            status=payment.status.value,
            amount_paise=payment.amount_paise,
            method=payment.method.value,
            cashfree=session,
        )


class WebhookAck(_Camel):
    ok: bool = True


class TopupRequest(_Camel):
    amount_paise: int = Field(gt=0)


class LedgerItemOut(_Camel):
    id: str
    direction: str
    amount_paise: int
    reason: str
    created_at: datetime


class WalletOut(_Camel):
    balance_paise: int
    items: list[LedgerItemOut]


class ValidateCouponRequest(_Camel):
    code: str
    labor_paise: int = 0


class CouponQuoteOut(_Camel):
    code: str
    discount_paise: int
    message: str


class CouponOut(_Camel):
    code: str
    title: str
    description: str
    type: str
    amount: int
    max_discount_paise: int
    min_labor_paise: int
    ends_at: datetime

    @classmethod
    def of(cls, coupon: Coupon) -> "CouponOut":
        return cls(
            code=coupon.code,
            title=coupon.title,
            description=coupon.description,
            type=coupon.type.value,
            amount=coupon.amount,
            max_discount_paise=coupon.max_discount_paise,
            min_labor_paise=coupon.min_labor_paise,
            ends_at=coupon.ends_at,
        )


class CouponListOut(_Camel):
    items: list[CouponOut]


class RefundRequest(_Camel):
    payment_id: str
    amount_paise: int


class EarningOut(_Camel):
    booking_id: str
    display_number: str
    paid_at: datetime
    total_paise: int
    share_paise: int
    payout_status: str


class EarningsListOut(_Camel):
    items: list[EarningOut]
    notice: str = "Recorded earnings. Bank payout is not live yet."


@router.post("", response_model=PaymentOut, status_code=201)
async def create_payment(
    body: CreatePaymentRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[CreatePayment, Depends(create_payment_dep)],
    idempotency_key: Annotated[str | None, Header()] = None,
) -> PaymentOut:
    payment = await use_case.execute(
        principal,
        idempotency_key=idempotency_key,
        booking_id=body.booking_id,
        method=body.method,
    )
    return PaymentOut.of(payment)


@router.post("/cashfree/webhook", response_model=WebhookAck)
async def cashfree_webhook(
    request: Request,
    gateway: Annotated[PaymentGateway, Depends(payment_gateway_dep)],
    apply: Annotated[ApplyGatewayEvent, Depends(apply_gateway_event_dep)],
) -> WebhookAck:
    raw = await request.body()
    headers = {k.lower(): v for k, v in request.headers.items()}
    event = await gateway.verify_webhook(headers, raw)
    await apply.execute(event)
    return WebhookAck()


@router.post("/{payment_id}/cash-collected", response_model=PaymentOut)
async def cash_collected(
    payment_id: str,
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[MarkCashCollected, Depends(mark_cash_collected_dep)],
) -> PaymentOut:
    return PaymentOut.of(await use_case.execute(principal, payment_id))


@router.post("/{payment_id}/cash-confirm", response_model=PaymentOut)
async def cash_confirm(
    payment_id: str,
    body: CashDecisionRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ConfirmCash, Depends(confirm_cash_dep)],
) -> PaymentOut:
    return PaymentOut.of(await use_case.execute(principal, payment_id, paid=body.paid))


@router.get("/{payment_id}", response_model=PaymentOut)
async def get_payment(
    payment_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
) -> PaymentOut:
    payment = await payments.get(payment_id)
    if payment is None or payment.payer_id != principal.user_id:
        raise NotFound("We could not find that payment.")
    return PaymentOut.of(payment)


@wallet_router.get("", response_model=WalletOut)
async def get_wallet(
    principal: Annotated[Principal, Depends(principal_dep)],
    wallet: Annotated[WalletService, Depends(wallet_service_dep)],
) -> WalletOut:
    balance = await wallet.balance(principal.user_id)
    items = await wallet.list_entries(principal.user_id)
    return WalletOut(
        balance_paise=balance.paise,
        items=[
            LedgerItemOut(
                id=item.id,
                direction=item.direction.value,
                amount_paise=item.amount_paise,
                reason=item.reason.value,
                created_at=item.created_at,
            )
            for item in items
        ],
    )


@wallet_router.post("/topups", response_model=PaymentOut, status_code=201)
async def create_topup(
    body: TopupRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[CreateWalletTopup, Depends(create_wallet_topup_dep)],
    idempotency_key: Annotated[str | None, Header()] = None,
) -> PaymentOut:
    payment = await use_case.execute(
        principal, idempotency_key=idempotency_key, amount_paise=body.amount_paise
    )
    return PaymentOut.of(payment)


@coupons_router.get("", response_model=CouponListOut)
async def list_coupons(
    principal: Annotated[Principal, Depends(principal_dep)],
    coupons: Annotated[CouponService, Depends(coupon_service_dep)],
) -> CouponListOut:
    _ = principal
    items = await coupons.list_active()
    return CouponListOut(items=[CouponOut.of(item) for item in items])


@coupons_router.post("/validate", response_model=CouponQuoteOut)
async def validate_coupon(
    body: ValidateCouponRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    coupons: Annotated[CouponService, Depends(coupon_service_dep)],
) -> CouponQuoteOut:
    quoted = await coupons.validate(
        body.code,
        CouponContext(user_id=principal.user_id, labor_paise=body.labor_paise),
    )
    return CouponQuoteOut(
        code=quoted.code, discount_paise=quoted.discount_paise, message=quoted.message
    )


@admin_router.post("/payments/{payment_id}/cash-confirm", response_model=PaymentOut)
async def staff_cash_confirm(
    payment_id: str,
    body: StaffCashRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[StaffConfirmCash, Depends(staff_confirm_cash_dep)],
) -> PaymentOut:
    return PaymentOut.of(await use_case.execute(principal, payment_id, note=body.note))


@admin_router.post("/refunds", response_model=PaymentOut)
async def create_refund(
    body: RefundRequest,
    request: Request,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[RefundPayment, Depends(refund_payment_dep)],
    idempotency_key: Annotated[str | None, Header()] = None,
) -> PaymentOut:
    request_id = request.headers.get("X-Request-Id", getattr(request.state, "request_id", ""))
    payment = await use_case.execute(
        principal,
        payment_id=body.payment_id,
        amount_paise=body.amount_paise,
        idempotency_key=idempotency_key,
        request_id=str(request_id),
    )
    return PaymentOut.of(payment)


@earnings_router.get("/earnings", response_model=EarningsListOut)
async def list_mechanic_earnings(
    principal: Annotated[Principal, Depends(require_mechanic_dep)],
    use_case: Annotated[ListEarnings, Depends(list_earnings_dep)],
) -> EarningsListOut:
    rows = await use_case.execute(principal)
    return EarningsListOut(
        items=[
            EarningOut(
                booking_id=row.booking_id,
                display_number=row.display_number,
                paid_at=row.paid_at,
                total_paise=row.total_paise,
                share_paise=row.share_paise,
                payout_status=row.payout_status,
            )
            for row in rows
        ]
    )


class ReconcileOut(_Camel):
    applied: int


@internal_router.post(
    "/reconcile-payments",
    response_model=ReconcileOut,
    dependencies=[Depends(require_internal_job_dep)],
)
async def reconcile_payments(
    use_case: Annotated[ReconcilePendingPayments, Depends(reconcile_pending_dep)],
) -> ReconcileOut:
    applied = await use_case.execute()
    return ReconcileOut(applied=applied)
