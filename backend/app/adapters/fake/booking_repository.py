from app.domain.booking import Booking


class FakeBookingRepository:
    """In-memory bookings keyed by id."""

    def __init__(self) -> None:
        self.bookings: dict[str, Booking] = {}

    async def get(self, booking_id: str) -> Booking | None:
        return self.bookings.get(booking_id)

    async def save(self, booking: Booking) -> Booking:
        self.bookings[booking.id] = booking
        return booking

    async def list_by_customer(self, customer_id: str) -> list[Booking]:
        return [b for b in self.bookings.values() if b.customer_id == customer_id]

    async def list_by_mechanic(self, mechanic_id: str) -> list[Booking]:
        return [b for b in self.bookings.values() if b.mechanic_id == mechanic_id]
