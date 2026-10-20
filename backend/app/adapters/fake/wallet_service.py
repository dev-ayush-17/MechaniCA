from app.domain.errors import InsufficientWallet
from app.domain.wallet import LedgerDirection, LedgerEntry, Money


class FakeWalletService:
    """In-memory ledger. Booking debits cannot go negative; cancel-fee debt can."""

    def __init__(self) -> None:
        self.entries: dict[str, list[LedgerEntry]] = {}
        self._by_id: dict[str, LedgerEntry] = {}

    async def balance(self, user_id: str) -> Money:
        total = 0
        for entry in self.entries.get(user_id, []):
            if entry.direction is LedgerDirection.CREDIT:
                total += entry.amount_paise
            else:
                total -= entry.amount_paise
        return Money(total)

    async def credit(self, user_id: str, entry: LedgerEntry) -> LedgerEntry:
        return self._append(user_id, entry)

    async def debit(self, user_id: str, entry: LedgerEntry) -> LedgerEntry:
        existing = self._by_id.get(entry.id)
        if existing is not None:
            return existing
        current = await self.balance(user_id)
        if current.paise - entry.amount_paise < 0:
            raise InsufficientWallet("Wallet balance is too low.")
        return self._append(user_id, entry)

    async def record_debt(self, user_id: str, entry: LedgerEntry) -> LedgerEntry:
        return self._append(user_id, entry)

    async def list_entries(self, user_id: str, *, limit: int = 50) -> list[LedgerEntry]:
        items = list(reversed(self.entries.get(user_id, [])))
        return items[:limit]

    def _append(self, user_id: str, entry: LedgerEntry) -> LedgerEntry:
        existing = self._by_id.get(entry.id)
        if existing is not None:
            return existing
        self.entries.setdefault(user_id, []).append(entry)
        self._by_id[entry.id] = entry
        return entry
