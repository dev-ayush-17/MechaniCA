from app.domain.booking import Booking
from app.domain.booking_state import BookingStatus
from app.domain.location import BookingGate
from app.ports.location_tracking import LocationTrackingService

_OPEN = frozenset(
    {
        BookingStatus.MECHANIC_ASSIGNED,
        BookingStatus.EN_ROUTE,
        BookingStatus.ARRIVED,
    }
)


async def sync_location_gate(locations: LocationTrackingService, booking: Booking) -> None:
    """API-only writer for bookingGates/{id}. Clients never call this."""
    await locations.set_gate(
        BookingGate(
            booking_id=booking.id,
            customer_id=booking.customer_id,
            mechanic_id=booking.mechanic_id,
            location_open=booking.status in _OPEN and booking.mechanic_id is not None,
        )
    )
