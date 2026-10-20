"""Payment value objects. Amounts are integer paise."""

from dataclasses import dataclass, replace
from datetime import datetime
from enum import StrEnum

from app.domain.booking import PaymentMethod


class PaymentStatus(StrEnum):
    CREATED = "created"
    PENDING = "pending"
    PAID = "paid"
    FAILED = "failed"
    REFUNDED = "refunded"
    PARTIALLY_REFUNDED = "partially_refunded"


class PaymentGatewayKind(StrEnum):
    CASHFREE = "cashfree"
    WALLET = "wallet"
    CASH = "cash"
    NONE = "none"


class PaymentReason(StrEnum):
    BOOKING = "booking"
    TOPUP = "topup"
    CANCEL_FEE = "cancel_fee"


ONLINE_METHODS = frozenset({PaymentMethod.UPI, PaymentMethod.CARD, PaymentMethod.NETBANKING})


@dataclass(frozen=True)
class Payment:
    id: str
    booking_id: str | None
    payer_id: str
    method: PaymentMethod
    amount_paise: int
    status: PaymentStatus
    gateway: PaymentGatewayKind
    gateway_order_id: str | None
    payment_session_id: str | None
    idempotency_key: str
    reason: PaymentReason
    refunded_paise: int
    cash_mechanic_marked_at: datetime | None
    cash_customer_marked_at: datetime | None
    cash_staff_note: str | None
    applied_event_ids: tuple[str, ...]
    created_at: datetime
    updated_at: datetime
    version: int

    def with_event(self, event_id: str, *, now: datetime, **changes: object) -> "Payment":
        ids = (
            self.applied_event_ids
            if event_id in self.applied_event_ids
            else (
                *self.applied_event_ids,
                event_id,
            )
        )
        return replace(
            self,
            applied_event_ids=ids,
            updated_at=now,
            version=self.version + 1,
            **changes,  # type: ignore[arg-type]
        )


@dataclass(frozen=True)
class PaymentOrder:
    payment_id: str
    amount_paise: int
    customer_id: str
    customer_phone: str | None = None
    currency: str = "INR"


@dataclass(frozen=True)
class GatewayOrder:
    gateway_order_id: str
    payment_session_id: str
    amount_paise: int
    status: str


@dataclass(frozen=True)
class GatewayEvent:
    event_id: str
    gateway_order_id: str
    amount_paise: int
    status: str


@dataclass(frozen=True)
class RefundResult:
    refund_id: str
    amount_paise: int
    status: str
