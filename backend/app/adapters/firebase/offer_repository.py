"""Firestore offers/{id}. One open offer per booking is enforced by the use case."""

from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.domain.dispatch import Offer, OfferStatus


def _parse_time(value: object) -> datetime:
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


def offer_to_doc(offer: Offer) -> dict[str, object]:
    return {
        "bookingId": offer.booking_id,
        "mechanicId": offer.mechanic_id,
        "status": offer.status.value,
        "expiresAt": offer.expires_at,
        "attempt": offer.attempt,
        "score": offer.score,
        "distanceKm": offer.distance_km,
        "createdAt": offer.created_at,
    }


def offer_from_doc(offer_id: str, data: dict[str, object]) -> Offer:
    return Offer(
        id=offer_id,
        booking_id=str(data["bookingId"]),
        mechanic_id=str(data["mechanicId"]),
        status=OfferStatus(str(data.get("status", OfferStatus.OPEN.value))),
        expires_at=_parse_time(data["expiresAt"]),
        attempt=int(str(data.get("attempt", 1))),
        score=float(str(data.get("score", 0))),
        distance_km=float(str(data.get("distanceKm", 0))),
        created_at=_parse_time(data["createdAt"]),
    )


class FirestoreOfferRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self) -> Any:
        return self._db.collection("offers")

    def _all(self) -> list[Offer]:
        return [offer_from_doc(snap.id, snap.to_dict() or {}) for snap in self._col().stream()]

    async def get(self, offer_id: str) -> Offer | None:
        snap = self._col().document(offer_id).get()
        if not snap.exists:
            return None
        return offer_from_doc(snap.id, snap.to_dict() or {})

    async def save(self, offer: Offer) -> Offer:
        self._col().document(offer.id).set(offer_to_doc(offer))
        return offer

    async def list_by_booking(self, booking_id: str) -> list[Offer]:
        snaps = self._col().where("bookingId", "==", booking_id).stream()
        return [offer_from_doc(s.id, s.to_dict() or {}) for s in snaps]

    async def list_by_mechanic(self, mechanic_id: str) -> list[Offer]:
        snaps = self._col().where("mechanicId", "==", mechanic_id).stream()
        return [offer_from_doc(s.id, s.to_dict() or {}) for s in snaps]

    async def list_open(self) -> list[Offer]:
        snaps = self._col().where("status", "==", OfferStatus.OPEN.value).stream()
        return [offer_from_doc(s.id, s.to_dict() or {}) for s in snaps]

    async def list_expired_open(self, now: datetime) -> list[Offer]:
        expired: list[Offer] = []
        for item in self._all():
            if item.status is not OfferStatus.OPEN:
                continue
            expires = item.expires_at
            if expires.tzinfo is None and now.tzinfo is not None:
                expires = expires.replace(tzinfo=now.tzinfo)
            if expires <= now:
                expired.append(item)
        return expired
