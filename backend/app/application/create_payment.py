import uuid
from dataclasses import dataclass, replace

from app.application.create_booking import hash_create_body, parse_idempotency_key
from app.application.invoices import schedule_invoice_render
from app.domain.booking import Booking, LineKind, LineStatus, PaymentMethod
from app.domain.booking_state import BookingStatus, assert_transition
from app.domain.catalog import BPS_DENOMINATOR
from app.domain.coupon import CouponContext
from app.domain.errors import (
    Conflict,
    InvalidTransition,
    NotFound,
    PermissionDenied,
    TotalChanged,
)
from app.domain.payment import (
    ONLINE_METHODS,
    Payment,
    PaymentGatewayKind,
    PaymentOrder,
    PaymentReason,
    PaymentStatus,
)
from app.domain.user import Principal, Role
from app.domain.wallet import LedgerDirection, LedgerEntry, LedgerReason
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.coupon_service import CouponService
from app.ports.job_scheduler import JobScheduler
from app.ports.payment_gateway import PaymentGateway
from app.ports.payment_repository import PaymentRepository
from app.ports.wallet_service import WalletService


def recompute_total_paise(booking: Booking, *, gst_bps: int, discount_paise: int) -> int:
    parts = sum(
        line.amount_paise
        for line in booking.lines
        if line.kind is LineKind.PART and line.status in {LineStatus.INCLUDED, LineStatus.APPROVED}
    )
    labor = booking.labor_paise
    fee = booking.fee_paise
    taxable = labor + fee + parts
    gst_total = taxable * gst_bps // BPS_DENOMINATOR
    return taxable - discount_paise + gst_total


@dataclass(frozen=True)
class CreatePayment:
    payments: PaymentRepository
    bookings: BookingRepository
    gateway: PaymentGateway
    wallet: WalletService
    coupons: CouponService
    clock: Clock
    gst_bps: int
    scheduler: JobScheduler | None = None
    demo_wallet_float: bool = False

    async def execute(
        self,
        principal: Principal,
        *,
        idempotency_key: str | None,
        booking_id: str,
        method: PaymentMethod,
    ) -> Payment:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        key = parse_idempotency_key(idempotency_key)
        body_hash = hash_create_body({"bookingId": booking_id, "method": method.value})
        existing = await self.payments.get_by_idempotency(principal.user_id, key)
        if existing is not None:
            prior = hash_create_body(
                {"bookingId": existing.booking_id or "", "method": existing.method.value}
            )
            if prior != body_hash:
                raise Conflict("This key was already used with a different request.")
            return existing

        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        if booking.customer_id != principal.user_id:
            raise PermissionDenied("You do not have access to that booking.")
        if booking.status is BookingStatus.PAID:
            raise InvalidTransition("This booking is already paid.")
        if booking.status is not BookingStatus.COMPLETED:
            raise InvalidTransition("Pay after the visit is completed.")

        open_pay = await self.payments.get_by_booking(booking.id)
        if open_pay is not None and open_pay.status in {
            PaymentStatus.CREATED,
            PaymentStatus.PENDING,
            PaymentStatus.PAID,
        }:
            raise Conflict("A payment is already in progress for this booking.")

        discount = booking.discount_paise
        if booking.coupon_code.strip():
            history = await self.bookings.list_by_customer(principal.user_id)
            redeemed = await self.coupons.redeem(
                booking.coupon_code,
                booking.id,
                CouponContext(
                    user_id=principal.user_id,
                    labor_paise=booking.labor_paise,
                    prior_booking_count=max(0, len(history) - 1),
                ),
            )
            discount = redeemed.discount_paise
        total = recompute_total_paise(booking, gst_bps=self.gst_bps, discount_paise=discount)
        if total != booking.total_paise:
            raise TotalChanged("The total changed. Refresh the bill and try again.")

        now = self.clock.now()
        payment_id = str(uuid.uuid4())
        if method in ONLINE_METHODS:
            gateway_kind = PaymentGatewayKind.CASHFREE
            status = PaymentStatus.PENDING
        elif method is PaymentMethod.WALLET:
            gateway_kind = PaymentGatewayKind.WALLET
            status = PaymentStatus.CREATED
        else:
            gateway_kind = PaymentGatewayKind.CASH
            status = PaymentStatus.PENDING

        payment = Payment(
            id=payment_id,
            booking_id=booking.id,
            payer_id=principal.user_id,
            method=method,
            amount_paise=total,
            status=status,
            gateway=gateway_kind,
            gateway_order_id=None,
            payment_session_id=None,
            idempotency_key=key,
            reason=PaymentReason.BOOKING,
            refunded_paise=0,
            cash_mechanic_marked_at=None,
            cash_customer_marked_at=None,
            cash_staff_note=None,
            applied_event_ids=(),
            created_at=now,
            updated_at=now,
            version=1,
        )
        if method in ONLINE_METHODS:
            order = await self.gateway.create_order(
                PaymentOrder(
                    payment_id=payment.id,
                    amount_paise=total,
                    customer_id=principal.user_id,
                    customer_phone=principal.phone_e164,
                )
            )
            payment = replace(
                payment,
                gateway_order_id=order.gateway_order_id,
                payment_session_id=order.payment_session_id,
            )
        saved = await self.payments.insert(payment)
        if method is PaymentMethod.WALLET:
            if self.demo_wallet_float:
                balance = await self.wallet.balance(principal.user_id)
                shortfall = total - balance.paise
                if shortfall > 0:
                    await self.wallet.credit(
                        principal.user_id,
                        LedgerEntry(
                            id=f"demo_float_{payment_id}",
                            user_id=principal.user_id,
                            booking_id=booking.id,
                            direction=LedgerDirection.CREDIT,
                            amount_paise=shortfall,
                            reason=LedgerReason.ADJUSTMENT,
                            created_at=now,
                        ),
                    )
            await self.wallet.debit(
                principal.user_id,
                LedgerEntry(
                    id=f"wallet_{saved.id}",
                    user_id=principal.user_id,
                    booking_id=booking.id,
                    direction=LedgerDirection.DEBIT,
                    amount_paise=total,
                    reason=LedgerReason.BOOKING_PAYMENT,
                    created_at=now,
                ),
            )
            paid = replace(
                saved,
                status=PaymentStatus.PAID,
                updated_at=now,
                version=saved.version + 1,
            )
            saved = await self.payments.save(paid, expected_version=saved.version)
            assert_transition(booking.status, BookingStatus.PAID, "system")
            await self.bookings.save(booking.with_status(BookingStatus.PAID, now=now))
            await schedule_invoice_render(self.scheduler, booking.id, now)
        return saved
