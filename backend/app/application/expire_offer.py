from dataclasses import dataclass

from app.application.dispatch import SequentialDispatch


@dataclass(frozen=True)
class ExpireOffer:
    """Timeout handler. Safe to run twice; a non-open offer is a no-op."""

    dispatch: SequentialDispatch

    async def execute(self, offer_id: str) -> None:
        await self.dispatch.expire(offer_id)
