from app.domain.tracking import TrackingLink


class FakeTrackingLinkStore:
    def __init__(self) -> None:
        self.links: dict[str, TrackingLink] = {}

    async def save(self, link: TrackingLink) -> TrackingLink:
        self.links[link.token] = link
        return link

    async def get(self, token: str) -> TrackingLink | None:
        return self.links.get(token)
