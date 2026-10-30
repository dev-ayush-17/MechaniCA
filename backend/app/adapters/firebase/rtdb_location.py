"""Admin SDK writes bookingGates and reads liveLocations. Clients never write gates."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

import firebase_admin
from firebase_admin import db

from app.domain.location import BookingGate, LocationPoint, LocationSnapshot, accept_point


class RtdbLocationTrackingService:
    def __init__(self, project_id: str, database_url: str) -> None:
        try:
            self._app = firebase_admin.get_app()
        except ValueError:
            self._app = firebase_admin.initialize_app(
                options={"projectId": project_id, "databaseURL": database_url}
            )

    async def publish(self, booking_id: str, role: str, point: LocationPoint) -> None:
        current = await self.latest(booking_id) or LocationSnapshot()
        previous = current.mechanic if role == "mechanic" else current.customer
        kept = accept_point(previous, point)
        if kept is None:
            return
        ref = db.reference(f"liveLocations/{booking_id}/{role}", app=self._app)
        ref.set(_point_payload(kept))

    async def latest(self, booking_id: str) -> LocationSnapshot | None:
        raw = db.reference(f"liveLocations/{booking_id}", app=self._app).get()
        if not isinstance(raw, dict):
            return None
        return LocationSnapshot(
            mechanic=_parse_point(raw.get("mechanic")),
            customer=_parse_point(raw.get("customer")),
        )

    async def set_gate(self, gate: BookingGate) -> None:
        db.reference(f"bookingGates/{gate.booking_id}", app=self._app).set(
            {
                "customerId": gate.customer_id,
                "mechanicId": gate.mechanic_id,
                "locationOpen": gate.location_open,
            }
        )

    async def get_gate(self, booking_id: str) -> BookingGate | None:
        raw = db.reference(f"bookingGates/{booking_id}", app=self._app).get()
        if not isinstance(raw, dict):
            return None
        mechanic_id = raw.get("mechanicId")
        return BookingGate(
            booking_id=booking_id,
            customer_id=str(raw.get("customerId") or ""),
            mechanic_id=str(mechanic_id) if mechanic_id else None,
            location_open=bool(raw.get("locationOpen")),
        )


def _point_payload(point: LocationPoint) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "lat": point.lat,
        "lng": point.lng,
        "accuracyM": point.accuracy_m,
        "recordedAt": point.recorded_at.isoformat(),
    }
    if point.speed_mps is not None:
        payload["speedMps"] = point.speed_mps
    return payload


def _parse_point(raw: object) -> LocationPoint | None:
    if not isinstance(raw, dict):
        return None
    recorded = raw.get("recordedAt")
    if recorded is None:
        return None
    when = (
        datetime.fromisoformat(str(recorded).replace("Z", "+00:00"))
        if not isinstance(recorded, datetime)
        else recorded
    )
    if when.tzinfo is None:
        when = when.replace(tzinfo=UTC)
    return LocationPoint(
        lat=float(raw["lat"]),
        lng=float(raw["lng"]),
        accuracy_m=float(raw.get("accuracyM") or 0),
        recorded_at=when,
        speed_mps=float(raw["speedMps"]) if raw.get("speedMps") is not None else None,
    )
