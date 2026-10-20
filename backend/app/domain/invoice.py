"""GST invoice value objects. Money fields are integer paise."""

from dataclasses import dataclass
from datetime import datetime
from zoneinfo import ZoneInfo

from app.domain.booking import Booking, LineKind, LineStatus
from app.domain.errors import InvalidInput

IST = ZoneInfo("Asia/Kolkata")


@dataclass(frozen=True)
class InvoiceLine:
    name: str
    quantity: int
    amount_paise: int


@dataclass(frozen=True)
class InvoiceFile:
    booking_id: str
    number: str
    version: int
    storage_path: str
    total_paise: int
    cgst_paise: int
    sgst_paise: int
    gstin: str
    customer_name: str
    vehicle_registration: str
    mechanic_display_name: str
    payment_method: str
    lines: tuple[InvoiceLine, ...]
    created_at: datetime


def invoice_period(at: datetime) -> str:
    return at.astimezone(IST).strftime("%Y%m")


def format_invoice_number(yyyymm: str, sequence: int) -> str:
    if len(yyyymm) != 6 or not yyyymm.isdigit():
        raise InvalidInput("Invoice period is invalid.")
    if sequence < 1 or sequence > 999_999:
        raise InvalidInput("Invoice sequence is invalid.")
    return f"MC-{yyyymm}-{sequence:06d}"


def invoice_pdf_path(booking_id: str, version: int) -> str:
    if ".." in booking_id or "/" in booking_id or "\\" in booking_id:
        raise InvalidInput("That path is not allowed.", fields={"bookingId": "invalid"})
    if version < 1:
        raise InvalidInput("Invoice version is invalid.")
    return f"invoices/{booking_id}/v{version}.pdf"


def lines_from_booking(booking: Booking) -> tuple[InvoiceLine, ...]:
    items: list[InvoiceLine] = []
    if booking.labor_paise:
        items.append(
            InvoiceLine(name=booking.service_name, quantity=1, amount_paise=booking.labor_paise)
        )
    if booking.fee_paise:
        items.append(
            InvoiceLine(name="Convenience fee", quantity=1, amount_paise=booking.fee_paise)
        )
    parts = [
        line
        for line in booking.lines
        if line.kind is LineKind.PART
        and line.status in {LineStatus.INCLUDED, LineStatus.APPROVED}
    ]
    if parts:
        items.extend(
            InvoiceLine(name=line.name, quantity=1, amount_paise=line.amount_paise)
            for line in parts
        )
    elif booking.parts_paise:
        items.append(InvoiceLine(name="Parts", quantity=1, amount_paise=booking.parts_paise))
    if booking.discount_paise:
        items.append(
            InvoiceLine(name="Discount", quantity=1, amount_paise=-booking.discount_paise)
        )
    return tuple(items)
