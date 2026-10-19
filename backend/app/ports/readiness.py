from typing import Protocol


class ReadinessCheck(Protocol):
    """Reports whether downstream dependencies are usable. Real adapters arrive with M02+."""

    async def check(self) -> dict[str, bool]:
        """Map of dependency name to healthy."""
        ...
