from dataclasses import dataclass, replace

from app.application.create_booking import parse_idempotency_key
from app.domain.errors import AlreadyRefunded, InvalidInput, NotFound, PermissionDenied
from app.domain.payment import Payment, PaymentGatewayKind, PaymentStatus
from app.domain.user import Principal, Role
from app.domain.wallet import LedgerDirection, LedgerEntry, LedgerReason
from app.ports.clock import Clock
from app.ports.payment_gateway import PaymentGateway
from app.ports.payment_repository import PaymentRepository
from app.ports.wallet_service import WalletService


@dataclass(frozen=True)
class RefundPayment:
    payments: PaymentRepository
    gateway: PaymentGateway
    wallet: WalletService
    clock: Clock

    async def execute(
        self,
        principal: Principal,
        *,
        payment_id: str,
        amount_paise: int,
        idempotency_key: str | None,
    ) -> Payment:
        if principal.role not in {Role.ADMIN, Role.SUPER_ADMIN}:
            raise PermissionDenied("Admin access required.")
        parse_idempotency_key(idempotency_key)
        if amount_paise <= 0:
            raise InvalidInput("Amount must be greater than zero.")
        payment = await self.payments.get(payment_id)
        if payment is None:
            raise NotFound("We could not find that payment.")
        if payment.status in {PaymentStatus.REFUNDED, PaymentStatus.PARTIALLY_REFUNDED}:
            raise AlreadyRefunded("This payment was already refunded.")
        if payment.status is not PaymentStatus.PAID:
            raise InvalidInput("Only a paid payment can be refunded.")
        remaining = payment.amount_paise - payment.refunded_paise
        if amount_paise > remaining:
            raise InvalidInput("Refund cannot exceed the captured amount.")
        now = self.clock.now()
        if payment.gateway is PaymentGatewayKind.CASHFREE and payment.gateway_order_id:
            await self.gateway.refund(
                payment.gateway_order_id, amount_paise, idempotency_key or payment.id
            )
        else:
            await self.wallet.credit(
                payment.payer_id,
                LedgerEntry(
                    id=f"refund_{payment.id}",
                    user_id=payment.payer_id,
                    booking_id=payment.booking_id,
                    direction=LedgerDirection.CREDIT,
                    amount_paise=amount_paise,
                    reason=LedgerReason.REFUND,
                    created_at=now,
                ),
            )
        full = amount_paise == remaining
        updated = replace(
            payment,
            status=PaymentStatus.REFUNDED if full else PaymentStatus.PARTIALLY_REFUNDED,
            refunded_paise=payment.refunded_paise + amount_paise,
            updated_at=now,
            version=payment.version + 1,
        )
        return await self.payments.save(updated, expected_version=payment.version)
