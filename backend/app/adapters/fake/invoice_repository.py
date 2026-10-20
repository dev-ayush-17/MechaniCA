from app.domain.invoice import InvoiceFile


class FakeInvoiceRepository:
    """In-memory invoices/{bookingId} plus last sequence per YYYYMM."""

    def __init__(self) -> None:
        self.invoices: dict[str, InvoiceFile] = {}
        self.sequences: dict[str, int] = {}

    async def get(self, booking_id: str) -> InvoiceFile | None:
        return self.invoices.get(booking_id)

    async def save(self, invoice: InvoiceFile) -> InvoiceFile:
        self.invoices[invoice.booking_id] = invoice
        return invoice

    async def next_sequence(self, yyyymm: str) -> int:
        n = self.sequences.get(yyyymm, 0) + 1
        self.sequences[yyyymm] = n
        return n
