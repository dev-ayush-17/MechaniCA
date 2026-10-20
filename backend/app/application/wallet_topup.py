import uuid
from dataclasses import dataclass

from app.application.create_booking import hash_create_body, parse_idempotency_key
from app.domain.booking import PaymentMethod
from app.domain.errors import IdempotencyConflict, InvalidInput, PermissionDenied
from app.domain.payment import (
    Payment,
    PaymentGatewayKind,
    PaymentOrder,
    PaymentReason,
    PaymentStatus,
)
from app.domain.user import Principal, Role
from app.ports.clock import Clock
from app.ports.payment_gateway import PaymentGateway
from app.ports.payment_repository import PaymentRepository


@dataclass(frozen=True)
class CreateWalletTopup:
    payments: PaymentRepository
    gateway: PaymentGateway
    clock: Clock

    async def execute(
        self,
        principal: Principal,
        *,
        idempotency_key: str | None,
        amount_paise: int,
    ) -> Payment:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        if amount_paise <= 0:
            raise InvalidInput("Amount must be greater than zero.")
        key = parse_idempotency_key(idempotency_key)
        existing = await self.payments.get_by_idempotency(principal.user_id, key)
        if existing is not None:
            prior = hash_create_body({"amountPaise": existing.amount_paise, "reason": "topup"})
            incoming = hash_create_body({"amountPaise": amount_paise, "reason": "topup"})
            if prior != incoming:
                raise IdempotencyConflict("This key was already used with a different request.")
            return existing
        now = self.clock.now()
        payment_id = str(uuid.uuid4())
        order = await self.gateway.create_order(
            PaymentOrder(
                payment_id=payment_id,
                amount_paise=amount_paise,
                customer_id=principal.user_id,
                customer_phone=principal.phone_e164,
            )
        )
        payment = Payment(
            id=payment_id,
            booking_id=None,
            payer_id=principal.user_id,
            method=PaymentMethod.UPI,
            amount_paise=amount_paise,
            status=PaymentStatus.PENDING,
            gateway=PaymentGatewayKind.CASHFREE,
            gateway_order_id=order.gateway_order_id,
            payment_session_id=order.payment_session_id,
            idempotency_key=key,
            reason=PaymentReason.TOPUP,
            refunded_paise=0,
            cash_mechanic_marked_at=None,
            cash_customer_marked_at=None,
            cash_staff_note=None,
            applied_event_ids=(),
            created_at=now,
            updated_at=now,
            version=1,
        )
        return await self.payments.insert(payment)
