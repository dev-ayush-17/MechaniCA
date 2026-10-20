from datetime import datetime

from app.domain.dispatch import Offer, OfferStatus


class FakeOfferRepository:
    def __init__(self) -> None:
        self.offers: dict[str, Offer] = {}

    async def get(self, offer_id: str) -> Offer | None:
        return self.offers.get(offer_id)

    async def save(self, offer: Offer) -> Offer:
        self.offers[offer.id] = offer
        return offer

    async def list_by_booking(self, booking_id: str) -> list[Offer]:
        return [item for item in self.offers.values() if item.booking_id == booking_id]

    async def list_by_mechanic(self, mechanic_id: str) -> list[Offer]:
        return [item for item in self.offers.values() if item.mechanic_id == mechanic_id]

    async def list_open(self) -> list[Offer]:
        return [item for item in self.offers.values() if item.status is OfferStatus.OPEN]

    async def list_expired_open(self, now: datetime) -> list[Offer]:
        return [
            item
            for item in self.offers.values()
            if item.status is OfferStatus.OPEN and item.expires_at <= now
        ]
