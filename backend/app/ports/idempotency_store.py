from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


@dataclass(frozen=True)
class IdempotencyRecord:
    body_hash: str
    booking_id: str
    created_at: datetime


class IdempotencyStore(Protocol):
    """24-hour replay cache for booking create (docs/prd/12-api-contracts.md)."""

    async def get(self, user_id: str, key: str) -> IdempotencyRecord | None: ...

    async def put(self, user_id: str, key: str, record: IdempotencyRecord) -> None: ...
