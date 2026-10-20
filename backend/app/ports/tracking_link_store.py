from typing import Protocol

from app.domain.tracking import TrackingLink


class TrackingLinkStore(Protocol):
    async def save(self, link: TrackingLink) -> TrackingLink: ...

    async def get(self, token: str) -> TrackingLink | None: ...
