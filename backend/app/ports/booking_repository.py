from typing import Protocol

from app.domain.booking import Booking


class BookingRepository(Protocol):
    """Persists bookings. FastAPI is the only writer of status and money."""

    async def get(self, booking_id: str) -> Booking | None: ...

    async def save(self, booking: Booking) -> Booking: ...

    async def list_by_customer(self, customer_id: str) -> list[Booking]: ...

    async def list_by_mechanic(self, mechanic_id: str) -> list[Booking]: ...
