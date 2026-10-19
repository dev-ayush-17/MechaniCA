from app.ports.idempotency_store import IdempotencyRecord


class FakeIdempotencyStore:
    """In-memory idempotency rows keyed by (user_id, key)."""

    def __init__(self) -> None:
        self._rows: dict[tuple[str, str], IdempotencyRecord] = {}

    async def get(self, user_id: str, key: str) -> IdempotencyRecord | None:
        return self._rows.get((user_id, key))

    async def put(self, user_id: str, key: str, record: IdempotencyRecord) -> None:
        self._rows[(user_id, key)] = record
