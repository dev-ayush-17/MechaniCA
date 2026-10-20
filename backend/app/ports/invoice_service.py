from typing import Protocol

from app.domain.invoice import InvoiceFile


class InvoiceService(Protocol):
    """Render and load the GST PDF for a paid booking (FR-INV-001)."""

    async def render(self, booking_id: str) -> InvoiceFile: ...

    async def get(self, booking_id: str) -> InvoiceFile | None: ...
