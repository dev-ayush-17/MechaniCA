from datetime import datetime
from typing import Protocol


class Clock(Protocol):
    """Source of time. Tests substitute a fixed clock (docs/prd/08-port-catalog.md)."""

    def now(self) -> datetime:
        """Current instant, timezone-aware UTC."""
        ...
