from dataclasses import dataclass
from datetime import timedelta

from app.application.apply_payment import ApplyGatewayEvent
from app.domain.payment import GatewayEvent, PaymentGatewayKind, PaymentStatus
from app.ports.clock import Clock
from app.ports.payment_gateway import PaymentGateway
from app.ports.payment_repository import PaymentRepository

_PENDING_AGE = timedelta(minutes=5)


@dataclass(frozen=True)
class ReconcilePendingPayments:
    payments: PaymentRepository
    gateway: PaymentGateway
    apply: ApplyGatewayEvent
    clock: Clock

    async def execute(self) -> int:
        cutoff = self.clock.now() - _PENDING_AGE
        pending = await self.payments.list_pending_before(cutoff)
        applied = 0
        for payment in pending:
            if payment.gateway is not PaymentGatewayKind.CASHFREE or not payment.gateway_order_id:
                continue
            order = await self.gateway.fetch(payment.gateway_order_id)
            status = order.status.lower()
            if status in {"paid", "success"}:
                event_status = "success"
            elif status in {"failed", "expired", "cancelled"}:
                event_status = "failed"
            else:
                continue
            event = GatewayEvent(
                event_id=f"fetch:{order.gateway_order_id}:{status}",
                gateway_order_id=order.gateway_order_id,
                amount_paise=order.amount_paise,
                status=event_status,
            )
            result = await self.apply.execute(event)
            if result.status is not PaymentStatus.PENDING:
                applied += 1
        return applied
