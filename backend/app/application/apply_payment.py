"""Apply a verified gateway event. Shared by the webhook and the reconciler."""

import logging
import uuid
from dataclasses import dataclass, replace

from app.application.invoices import schedule_invoice_render
from app.application.location_gate import sync_location_gate
from app.domain.audit import AuditEvent
from app.domain.booking_state import BookingStatus, assert_transition
from app.domain.errors import NotFound
from app.domain.notification_templates import Channel
from app.domain.payment import GatewayEvent, Payment, PaymentReason, PaymentStatus
from app.domain.wallet import LedgerDirection, LedgerEntry, LedgerReason
from app.ports.audit_log import AuditLog
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.job_scheduler import JobScheduler
from app.ports.location_tracking import LocationTrackingService
from app.ports.notification_sender import NotificationSender, OutboundNotification
from app.ports.payment_repository import PaymentRepository
from app.ports.wallet_service import WalletService

_LOG = logging.getLogger("mechupp")


@dataclass(frozen=True)
class ApplyGatewayEvent:
    payments: PaymentRepository
    bookings: BookingRepository
    wallet: WalletService
    audit: AuditLog
    notifier: NotificationSender
    clock: Clock
    scheduler: JobScheduler | None = None
    locations: LocationTrackingService | None = None

    async def execute(self, event: GatewayEvent) -> Payment:
        payment = await self.payments.get_by_gateway_order(event.gateway_order_id)
        if payment is None:
            raise NotFound("We could not find that payment.")
        if event.event_id in payment.applied_event_ids:
            return payment
        now = self.clock.now()
        mismatched = (
            event.amount_paise != payment.amount_paise
            or event.gateway_order_id != payment.gateway_order_id
        )
        if mismatched:
            await self.audit.append(
                AuditEvent(
                    id=str(uuid.uuid4()),
                    actor_id="system",
                    role="system",
                    action="payment_mismatch",
                    target_type="payment",
                    target_id=payment.id,
                    summary="Gateway amount or order id did not match.",
                    request_id=event.event_id,
                    created_at=now,
                )
            )
            stored = replace(
                payment,
                applied_event_ids=(*payment.applied_event_ids, event.event_id),
                updated_at=now,
                version=payment.version + 1,
            )
            return await self.payments.save(stored, expected_version=payment.version)

        if payment.status is PaymentStatus.PAID:
            stored = replace(
                payment,
                applied_event_ids=(*payment.applied_event_ids, event.event_id),
                updated_at=now,
                version=payment.version + 1,
            )
            return await self.payments.save(stored, expected_version=payment.version)

        if event.status == "failed":
            stored = replace(
                payment,
                status=PaymentStatus.FAILED,
                applied_event_ids=(*payment.applied_event_ids, event.event_id),
                updated_at=now,
                version=payment.version + 1,
            )
            saved = await self.payments.save(stored, expected_version=payment.version)
            await self._notify(saved, "paymentFailed")
            return saved

        stored = replace(
            payment,
            status=PaymentStatus.PAID,
            applied_event_ids=(*payment.applied_event_ids, event.event_id),
            updated_at=now,
            version=payment.version + 1,
        )
        saved = await self.payments.save(stored, expected_version=payment.version)
        if saved.reason is PaymentReason.TOPUP:
            await self.wallet.credit(
                saved.payer_id,
                LedgerEntry(
                    id=f"wallet_{saved.id}",
                    user_id=saved.payer_id,
                    booking_id=None,
                    direction=LedgerDirection.CREDIT,
                    amount_paise=saved.amount_paise,
                    reason=LedgerReason.TOPUP,
                    created_at=now,
                ),
            )
        elif saved.booking_id:
            booking = await self.bookings.get(saved.booking_id)
            if booking is not None and booking.status is BookingStatus.COMPLETED:
                assert_transition(booking.status, BookingStatus.PAID, "system")
                paid = booking.with_status(BookingStatus.PAID, now=now)
                await self.bookings.save(paid)
                if self.locations is not None:
                    await sync_location_gate(self.locations, paid)
                await schedule_invoice_render(self.scheduler, saved.booking_id, now)
        await self._notify(saved, "paymentPaid")
        return saved

    async def _notify(self, payment: Payment, template_id: str) -> None:
        try:
            await self.notifier.send(
                OutboundNotification(
                    user_id=payment.payer_id,
                    channel=Channel.IN_APP,
                    template_id=template_id,
                    title="Payment update",
                    body="Your payment was updated.",
                    data={"paymentId": payment.id},
                    deep_link="/booking/details",
                )
            )
        except Exception as exc:
            _LOG.warning("notify failed after payment apply", extra={"fields": {"error": str(exc)}})
