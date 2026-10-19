from dataclasses import dataclass

from app.domain.mechanic import Mechanic, VerificationStatus
from app.ports.clock import Clock
from app.ports.mechanic_repository import MechanicRepository


@dataclass(frozen=True)
class CreateMechanicDraft:
    mechanics: MechanicRepository
    clock: Clock

    async def execute(self, mechanic_id: str) -> Mechanic:
        existing = await self.mechanics.get(mechanic_id)
        if existing is not None:
            return existing
        now = self.clock.now()
        draft = Mechanic(
            id=mechanic_id,
            display_name="",
            photo_path="",
            years_experience=0,
            languages=(),
            service_area=None,
            verified=False,
            verification_status=VerificationStatus.DRAFT,
            online=False,
            last_heartbeat_at=None,
            rating_avg=0.0,
            rating_count=0,
            version=1,
        )
        return await self.mechanics.save_profile(draft)
