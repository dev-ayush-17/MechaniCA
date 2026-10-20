from datetime import datetime

from app.domain.errors import Conflict
from app.domain.payment import Payment, PaymentStatus


class FakePaymentRepository:
    def __init__(self) -> None:
        self.payments: dict[str, Payment] = {}

    async def get(self, payment_id: str) -> Payment | None:
        return self.payments.get(payment_id)

    async def get_by_idempotency(self, payer_id: str, key: str) -> Payment | None:
        for payment in self.payments.values():
            if payment.payer_id == payer_id and payment.idempotency_key == key:
                return payment
        return None

    async def get_by_booking(self, booking_id: str) -> Payment | None:
        for payment in self.payments.values():
            if payment.booking_id == booking_id:
                return payment
        return None

    async def get_by_gateway_order(self, gateway_order_id: str) -> Payment | None:
        for payment in self.payments.values():
            if payment.gateway_order_id == gateway_order_id:
                return payment
        return None

    async def insert(self, payment: Payment) -> Payment:
        self.payments[payment.id] = payment
        return payment

    async def save(self, payment: Payment, *, expected_version: int) -> Payment:
        current = self.payments.get(payment.id)
        if current is None or current.version != expected_version:
            raise Conflict("Payment was updated. Try again.")
        self.payments[payment.id] = payment
        return payment

    async def list_pending_before(self, cutoff: datetime) -> list[Payment]:
        return [
            p
            for p in self.payments.values()
            if p.status is PaymentStatus.PENDING and p.updated_at < cutoff
        ]
