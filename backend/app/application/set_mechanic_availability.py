from dataclasses import dataclass

from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.mechanic import Mechanic, VerificationStatus
from app.domain.user import Principal, Role
from app.ports.mechanic_repository import MechanicRepository


@dataclass(frozen=True)
class SetMechanicAvailability:
    mechanics: MechanicRepository

    async def execute(self, principal: Principal, *, online: bool) -> Mechanic:
        if principal.role != Role.MECHANIC:
            raise PermissionDenied("Mechanic account required.")
        current = await self.mechanics.get(principal.user_id)
        if current is None:
            raise NotFound("Finish mechanic setup first.")
        if online:
            if not current.verified or current.verification_status != VerificationStatus.APPROVED:
                raise InvalidInput("Get verified before going online.")
        return await self.mechanics.set_availability(principal.user_id, online=online)
