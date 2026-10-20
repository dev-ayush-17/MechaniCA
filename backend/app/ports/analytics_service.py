from datetime import datetime
from typing import Protocol


class AnalyticsService(Protocol):
    """Chapter 18 events. Properties are allow-listed; unknown keys are dropped."""

    async def track(self, name: str, properties: dict[str, object]) -> None: ...

    def counts_since(self, start: datetime) -> dict[str, int]: ...
