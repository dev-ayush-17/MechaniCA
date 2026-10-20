from typing import Protocol

from app.domain.payment import GatewayEvent, GatewayOrder, PaymentOrder, RefundResult


class PaymentGateway(Protocol):
    """Cashfree (or fake) order, webhook verify, fetch, and refund."""

    async def create_order(self, order: PaymentOrder) -> GatewayOrder: ...

    async def verify_webhook(self, headers: dict[str, str], raw_body: bytes) -> GatewayEvent: ...

    async def refund(
        self, gateway_order_id: str, amount_paise: int, idempotency_key: str
    ) -> RefundResult: ...

    async def fetch(self, gateway_order_id: str) -> GatewayOrder: ...
