"""GST invoice PDF. reportlab lives here so domain and use cases stay vendor-free."""

from io import BytesIO

from reportlab.lib.pagesizes import A4
from reportlab.pdfgen.canvas import Canvas

from app.domain.invoice import InvoiceFile

_PAGE_H = A4[1]


def _inr(paise: int) -> str:
    sign = "-" if paise < 0 else ""
    rupees, rem = divmod(abs(paise), 100)
    return f"{sign}Rs {rupees}.{rem:02d}"


def render_invoice_pdf(invoice: InvoiceFile) -> bytes:
    buf = BytesIO()
    canvas = Canvas(buf, pagesize=A4, pageCompression=0)
    canvas.setTitle(invoice.number)
    y = _PAGE_H - 48
    canvas.setFont("Helvetica-Bold", 16)
    canvas.drawString(48, y, "MechUpp Tax Invoice")
    y -= 22
    canvas.setFont("Helvetica", 10)
    rows = [
        f"Invoice number: {invoice.number}",
        f"Date: {invoice.created_at.date().isoformat()}",
        f"Booking id: {invoice.booking_id}",
        f"Customer name: {invoice.customer_name}",
        f"Vehicle registration: {invoice.vehicle_registration}",
        f"Mechanic: {invoice.mechanic_display_name}",
        f"GSTIN: {invoice.gstin}",
        f"Payment method: {invoice.payment_method}",
        f"Version: v{invoice.version}",
    ]
    for row in rows:
        canvas.drawString(48, y, row)
        y -= 16
    y -= 8
    canvas.setFont("Helvetica-Bold", 11)
    canvas.drawString(48, y, "Line items")
    y -= 18
    canvas.setFont("Helvetica", 10)
    for line in invoice.lines:
        canvas.drawString(48, y, f"{line.name}  x{line.quantity}  {_inr(line.amount_paise)}")
        y -= 16
        if y < 80:
            canvas.showPage()
            y = _PAGE_H - 48
            canvas.setFont("Helvetica", 10)
    y -= 8
    canvas.drawString(48, y, f"CGST (9%): {_inr(invoice.cgst_paise)}")
    y -= 16
    canvas.drawString(48, y, f"SGST (9%): {_inr(invoice.sgst_paise)}")
    y -= 16
    canvas.setFont("Helvetica-Bold", 11)
    canvas.drawString(48, y, f"Total: {_inr(invoice.total_paise)}")
    canvas.save()
    return buf.getvalue()
