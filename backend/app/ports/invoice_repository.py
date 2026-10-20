from typing import Protocol

from app.domain.invoice import InvoiceFile


class InvoiceRepository(Protocol):
    """Persists invoice docs and the month-scoped number sequence. FastAPI is the only writer."""

    async def get(self, booking_id: str) -> InvoiceFile | None: ...

    async def save(self, invoice: InvoiceFile) -> InvoiceFile: ...

    async def next_sequence(self, yyyymm: str) -> int: ...
