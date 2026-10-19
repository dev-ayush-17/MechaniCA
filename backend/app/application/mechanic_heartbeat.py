from dataclasses import dataclass

from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.mechanic import Mechanic
from app.domain.user import Principal, Role
from app.ports.clock import Clock
from app.ports.mechanic_repository import MechanicRepository


@dataclass(frozen=True)
class MechanicHeartbeat:
    mechanics: MechanicRepository
    clock: Clock

    async def execute(self, principal: Principal) -> Mechanic:
        if principal.role != Role.MECHANIC:
            raise PermissionDenied("Mechanic account required.")
        current = await self.mechanics.get(principal.user_id)
        if current is None:
            raise NotFound("Finish mechanic setup first.")
        if not current.online:
            raise InvalidInput("Go online before sending a heartbeat.")
        return await self.mechanics.record_heartbeat(principal.user_id, at=self.clock.now())
