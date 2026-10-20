import logging
from dataclasses import dataclass
from datetime import UTC, datetime

from app.domain.analytics import sanitize_properties
from app.ports.clock import Clock

_LOG = logging.getLogger("mechupp")


@dataclass(frozen=True)
class TrackedEvent:
    name: str
    properties: dict[str, object]
    created_at: datetime


class LogAnalyticsService:
    """Structured-log adapter for AnalyticsService. Also records events for counts."""

    def __init__(self, clock: Clock | None = None) -> None:
        self.events: list[TrackedEvent] = []
        self._clock = clock

    async def track(self, name: str, properties: dict[str, object]) -> None:
        cleaned = sanitize_properties(properties)
        now = self._clock.now() if self._clock is not None else datetime.now(UTC)
        self.events.append(TrackedEvent(name=name, properties=cleaned, created_at=now))
        _LOG.info("analytics %s", name, extra={"fields": {"event": name, **cleaned}})

    def counts_since(self, start: datetime) -> dict[str, int]:
        counts: dict[str, int] = {}
        for event in self.events:
            if event.created_at >= start:
                counts[event.name] = counts.get(event.name, 0) + 1
        return counts
