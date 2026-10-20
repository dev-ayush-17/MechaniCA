from app.domain.location import BookingGate, LocationPoint, LocationSnapshot, accept_point


class FakeLocationTrackingService:
    """In-memory live points and booking gates. No Firebase."""

    def __init__(self) -> None:
        self._points: dict[str, LocationSnapshot] = {}
        self.gates: dict[str, BookingGate] = {}

    async def publish(self, booking_id: str, role: str, point: LocationPoint) -> None:
        current = self._points.get(booking_id, LocationSnapshot())
        if role == "mechanic":
            kept = accept_point(current.mechanic, point)
            if kept is None:
                return
            self._points[booking_id] = LocationSnapshot(mechanic=kept, customer=current.customer)
        elif role == "customer":
            kept = accept_point(current.customer, point)
            if kept is None:
                return
            self._points[booking_id] = LocationSnapshot(mechanic=current.mechanic, customer=kept)

    async def latest(self, booking_id: str) -> LocationSnapshot | None:
        return self._points.get(booking_id)

    async def set_gate(self, gate: BookingGate) -> None:
        self.gates[gate.booking_id] = gate

    async def get_gate(self, booking_id: str) -> BookingGate | None:
        return self.gates.get(booking_id)
