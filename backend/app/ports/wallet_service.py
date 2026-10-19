from typing import Protocol

from app.domain.wallet import LedgerEntry, Money


class WalletService(Protocol):
    """Append-only ledger. Debit refuses a negative booking-pay balance."""

    async def balance(self, user_id: str) -> Money: ...

    async def credit(self, user_id: str, entry: LedgerEntry) -> LedgerEntry: ...

    async def debit(self, user_id: str, entry: LedgerEntry) -> LedgerEntry: ...

    async def record_debt(self, user_id: str, entry: LedgerEntry) -> LedgerEntry: ...

    async def list_entries(self, user_id: str, *, limit: int = 50) -> list[LedgerEntry]: ...
