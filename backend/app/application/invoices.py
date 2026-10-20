"""Invoice render/get. PDF bytes come from an injected renderer (reportlab adapter)."""

from __future__ import annotations

import logging
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime

from app.domain.booking_state import BookingStatus
from app.domain.errors import InvalidTransition, NotFound, PermissionDenied
from app.domain.invoice import (
    InvoiceFile,
    format_invoice_number,
    invoice_pdf_path,
    invoice_period,
    lines_from_booking,
)
from app.domain.payment import PaymentReason, PaymentStatus
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.file_storage import FileStorage
from app.ports.invoice_repository import InvoiceRepository
from app.ports.invoice_service import InvoiceService
from app.ports.job_scheduler import JobScheduler, ScheduledJob
from app.ports.mechanic_repository import MechanicRepository
from app.ports.payment_repository import PaymentRepository
from app.ports.user_repository import UserRepository
from app.ports.vehicle_repository import VehicleRepository

_LOG = logging.getLogger("mechupp")

PdfRenderer = Callable[[InvoiceFile], bytes]


@dataclass(frozen=True)
class DefaultInvoiceService:
    invoices: InvoiceRepository
    storage: FileStorage
    bookings: BookingRepository
    payments: PaymentRepository
    users: UserRepository
    vehicles: VehicleRepository
    mechanics: MechanicRepository
    clock: Clock
    gstin: str
    render_pdf: PdfRenderer

    async def get(self, booking_id: str) -> InvoiceFile | None:
        return await self.invoices.get(booking_id)

    async def render(self, booking_id: str) -> InvoiceFile:
        existing = await self.invoices.get(booking_id)
        if existing is not None:
            return existing
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        if booking.status is not BookingStatus.PAID:
            raise InvalidTransition("Invoice is created after the booking is paid.")
        payment = await self.payments.get_by_booking(booking.id)
        if (
            payment is None
            or payment.status is not PaymentStatus.PAID
            or payment.reason is not PaymentReason.BOOKING
        ):
            raise NotFound("We could not find a paid payment for that booking.")
        now = self.clock.now()
        period = invoice_period(now)
        number = format_invoice_number(period, await self.invoices.next_sequence(period))
        customer = await self.users.get(booking.customer_id)
        vehicle = await self.vehicles.get(booking.vehicle_id, booking.customer_id)
        mechanic = (
            await self.mechanics.get(booking.mechanic_id) if booking.mechanic_id else None
        )
        invoice = InvoiceFile(
            booking_id=booking.id,
            number=number,
            version=1,
            storage_path=invoice_pdf_path(booking.id, 1),
            total_paise=payment.amount_paise,
            cgst_paise=booking.cgst_paise,
            sgst_paise=booking.sgst_paise,
            gstin=self.gstin,
            customer_name=customer.name if customer is not None else booking.customer_id,
            vehicle_registration=(
                vehicle.registration_number if vehicle is not None else booking.vehicle_id
            ),
            mechanic_display_name=mechanic.display_name if mechanic is not None else "—",
            payment_method=payment.method.value,
            lines=lines_from_booking(booking),
            created_at=now,
        )
        pdf = self.render_pdf(invoice)
        await self.storage.put(invoice.storage_path, pdf, "application/pdf")
        return await self.invoices.save(invoice)


@dataclass(frozen=True)
class GetInvoice:
    invoices: InvoiceService
    bookings: BookingRepository
    storage: FileStorage

    async def execute(self, principal: Principal, booking_id: str) -> tuple[InvoiceFile, str]:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that invoice.")
        if not _may_read(principal, booking.customer_id):
            raise PermissionDenied("You do not have access to that invoice.")
        invoice = await self.invoices.get(booking_id)
        if invoice is None:
            raise NotFound("We could not find that invoice.")
        download = await self.storage.signed_download(invoice.storage_path)
        return invoice, download.url


def _may_read(principal: Principal, customer_id: str) -> bool:
    if principal.role in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}:
        return True
    return principal.role is Role.CUSTOMER and principal.user_id == customer_id


async def schedule_invoice_render(
    scheduler: JobScheduler | None, booking_id: str, now: datetime
) -> None:
    if scheduler is None:
        return
    try:
        await scheduler.schedule(
            ScheduledJob(
                id=f"invoice-render-{booking_id}",
                run_at=now,
                target_path="/v1/internal/invoices/render",
                body={"bookingId": booking_id},
            )
        )
    except Exception as exc:
        _LOG.warning(
            "invoice_schedule_failed",
            extra={"fields": {"bookingId": booking_id, "error": type(exc).__name__}},
        )
