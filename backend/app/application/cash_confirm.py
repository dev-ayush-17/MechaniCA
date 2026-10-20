from dataclasses import dataclass, replace

from app.domain.booking import Booking
from app.domain.booking_state import BookingStatus, assert_transition
from app.domain.errors import InvalidInput, InvalidTransition, NotFound, PermissionDenied
from app.domain.notification_templates import Channel
from app.domain.payment import Payment, PaymentGatewayKind, PaymentStatus
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.notification_sender import NotificationSender, OutboundNotification
from app.ports.payment_repository import PaymentRepository


@dataclass(frozen=True)
class MarkCashCollected:
    payments: PaymentRepository
    bookings: BookingRepository
    notifier: NotificationSender
    clock: Clock

    async def execute(self, principal: Principal, payment_id: str) -> Payment:
        if principal.role != Role.MECHANIC:
            raise PermissionDenied("Mechanic account required.")
        payment, booking = await _load_cash(self.payments, self.bookings, payment_id)
        if booking.mechanic_id not in {None, principal.user_id}:
            raise PermissionDenied("You are not assigned to this booking.")
        if payment.cash_mechanic_marked_at is not None:
            return payment
        now = self.clock.now()
        updated = replace(
            payment,
            cash_mechanic_marked_at=now,
            updated_at=now,
            version=payment.version + 1,
        )
        saved = await self.payments.save(updated, expected_version=payment.version)
        await self.notifier.send(
            OutboundNotification(
                user_id=booking.customer_id,
                channel=Channel.IN_APP,
                template_id="cashConfirm",
                title="Confirm cash",
                body="Your mechanic marked cash collected.",
                data={"paymentId": saved.id},
                deep_link="/booking/details",
            )
        )
        return saved


@dataclass(frozen=True)
class ConfirmCash:
    payments: PaymentRepository
    bookings: BookingRepository
    clock: Clock

    async def execute(self, principal: Principal, payment_id: str, *, paid: bool) -> Payment:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        payment, booking = await _load_cash(self.payments, self.bookings, payment_id)
        if booking.customer_id != principal.user_id:
            raise PermissionDenied("You do not have access to that booking.")
        if payment.cash_mechanic_marked_at is None:
            raise InvalidInput("The mechanic has not marked cash collected yet.")
        now = self.clock.now()
        if not paid:
            disputed = booking.with_status(BookingStatus.DISPUTED, now=now)
            await self.bookings.save(disputed)
            return payment
        if payment.cash_customer_marked_at is not None and payment.status is PaymentStatus.PAID:
            return payment
        updated = replace(
            payment,
            cash_customer_marked_at=now,
            status=PaymentStatus.PAID,
            updated_at=now,
            version=payment.version + 1,
        )
        saved = await self.payments.save(updated, expected_version=payment.version)
        if booking.status is BookingStatus.COMPLETED:
            assert_transition(booking.status, BookingStatus.PAID, "system")
            await self.bookings.save(booking.with_status(BookingStatus.PAID, now=now))
        return saved


@dataclass(frozen=True)
class StaffConfirmCash:
    payments: PaymentRepository
    bookings: BookingRepository
    clock: Clock

    async def execute(self, principal: Principal, payment_id: str, *, note: str) -> Payment:
        if principal.role not in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}:
            raise PermissionDenied("Staff access required.")
        if not note.strip():
            raise InvalidInput("Add an audit note to confirm cash.")
        payment, booking = await _load_cash(self.payments, self.bookings, payment_id)
        now = self.clock.now()
        updated = replace(
            payment,
            cash_staff_note=note.strip(),
            cash_mechanic_marked_at=payment.cash_mechanic_marked_at or now,
            cash_customer_marked_at=payment.cash_customer_marked_at or now,
            status=PaymentStatus.PAID,
            updated_at=now,
            version=payment.version + 1,
        )
        saved = await self.payments.save(updated, expected_version=payment.version)
        if booking.status is BookingStatus.COMPLETED:
            assert_transition(booking.status, BookingStatus.PAID, "system")
            await self.bookings.save(booking.with_status(BookingStatus.PAID, now=now))
        return saved


async def _load_cash(
    payments: PaymentRepository, bookings: BookingRepository, payment_id: str
) -> tuple[Payment, Booking]:
    payment = await payments.get(payment_id)
    if payment is None or payment.booking_id is None:
        raise NotFound("We could not find that payment.")
    if payment.gateway is not PaymentGatewayKind.CASH:
        raise InvalidTransition("This payment is not cash.")
    booking = await bookings.get(payment.booking_id)
    if booking is None:
        raise NotFound("We could not find that booking.")
    return payment, booking
