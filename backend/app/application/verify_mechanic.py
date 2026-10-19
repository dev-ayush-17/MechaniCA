from dataclasses import dataclass
from enum import StrEnum
from uuid import uuid4

from app.domain.audit import AuditEvent
from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.mechanic import Mechanic, VerificationStatus
from app.domain.user import Principal, Role
from app.ports.audit_log import AuditLog
from app.ports.clock import Clock
from app.ports.mechanic_repository import MechanicRepository
from app.ports.role_claims import RoleClaims


class VerificationDecision(StrEnum):
    APPROVE = "approve"
    REJECT = "reject"


@dataclass(frozen=True)
class VerifyMechanic:
    mechanics: MechanicRepository
    claims: RoleClaims
    audit: AuditLog
    clock: Clock

    async def execute(
        self,
        principal: Principal,
        mechanic_id: str,
        *,
        decision: VerificationDecision,
        reason: str | None,
        request_id: str,
        record_audit: bool = True,
    ) -> Mechanic:
        if principal.role not in (Role.ADMIN, Role.SUPER_ADMIN):
            raise PermissionDenied("Admin access required.")
        current = await self.mechanics.get(mechanic_id)
        if current is None:
            raise NotFound("Mechanic not found.")
        if current.verification_status != VerificationStatus.PENDING:
            raise InvalidInput("This application is not pending review.")

        if decision == VerificationDecision.REJECT:
            cleaned = (reason or "").strip()
            if not cleaned:
                raise InvalidInput("Add a reason for rejection.", fields={"reason": "required"})
            status = VerificationStatus.REJECTED
            verified = False
            summary = f"Rejected mechanic application: {cleaned}"
        else:
            status = VerificationStatus.APPROVED
            verified = True
            summary = "Approved mechanic application."

        updated = await self.mechanics.set_verification(
            mechanic_id,
            status=status.value,
            verified=verified,
            reason=reason.strip() if reason else None,
            expected_version=current.version,
        )
        await self.claims.set_mechanic_verified(mechanic_id, verified)

        if record_audit:
            await self.audit.append(
                AuditEvent(
                    id=uuid4().hex,
                    actor_id=principal.user_id,
                    role=principal.role.value,
                    action=f"mechanic_verification_{decision.value}",
                    target_type="mechanic",
                    target_id=mechanic_id,
                    summary=summary,
                    request_id=request_id,
                    created_at=self.clock.now(),
                )
            )
        return updated
