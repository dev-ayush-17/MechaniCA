from typing import Protocol

from app.domain.booking import Booking
from app.domain.dispatch import Offer


class DispatchService(Protocol):
    async def offer(self, booking_id: str) -> Offer | None: ...

    async def accept(self, offer_id: str, mechanic_id: str) -> Booking: ...

    async def reject(self, offer_id: str, mechanic_id: str) -> None: ...

    async def expire(self, offer_id: str) -> None: ...
