from dataclasses import dataclass
from datetime import datetime

from app.domain.booking import Booking, LineKind, LineStatus
from app.domain.booking_state import BookingStatus
from app.domain.errors import PermissionDenied
from app.domain.payment import PaymentStatus
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.payment_repository import PaymentRepository


@dataclass(frozen=True)
class EarningRow:
    booking_id: str
    display_number: str
    paid_at: datetime
    total_paise: int
    share_paise: int
    payout_status: str


def mechanic_share_paise(booking: Booking, share_bps: int) -> int:
    parts = sum(
        line.amount_paise
        for line in booking.lines
        if line.kind is LineKind.PART and line.status in {LineStatus.INCLUDED, LineStatus.APPROVED}
    )
    return booking.labor_paise * share_bps // 10_000 + parts


@dataclass(frozen=True)
class ListEarnings:
    bookings: BookingRepository
    payments: PaymentRepository
    share_bps: int

    async def execute(self, principal: Principal) -> list[EarningRow]:
        if principal.role != Role.MECHANIC:
            raise PermissionDenied("Mechanic account required.")
        jobs = await self.bookings.list_by_mechanic(principal.user_id)
        rows: list[EarningRow] = []
        for booking in jobs:
            if booking.status is not BookingStatus.PAID:
                continue
            payment = await self.payments.get_by_booking(booking.id)
            if payment is None or payment.status is not PaymentStatus.PAID:
                continue
            rows.append(
                EarningRow(
                    booking_id=booking.id,
                    display_number=booking.display_number,
                    paid_at=payment.updated_at,
                    total_paise=booking.total_paise,
                    share_paise=mechanic_share_paise(booking, self.share_bps),
                    payout_status="recorded",
                )
            )
        rows.sort(key=lambda row: row.paid_at, reverse=True)
        return rows
