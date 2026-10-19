from datetime import UTC, datetime

from app.domain.errors import Conflict, NotFound
from app.domain.mechanic import Mechanic, MechanicDocument, ServiceArea, VerificationStatus


class FakeMechanicRepository:
    def __init__(self) -> None:
        self._mechanics: dict[str, Mechanic] = {}
        self._documents: dict[str, list[MechanicDocument]] = {}

    async def get(self, mechanic_id: str) -> Mechanic | None:
        return self._mechanics.get(mechanic_id)

    async def save_profile(self, mechanic: Mechanic) -> Mechanic:
        existing = self._mechanics.get(mechanic.id)
        if existing is not None:
            if existing.version != mechanic.version:
                raise Conflict("Profile changed elsewhere. Refresh and try again.")
            saved = Mechanic(
                id=mechanic.id,
                display_name=mechanic.display_name,
                photo_path=mechanic.photo_path,
                years_experience=mechanic.years_experience,
                languages=mechanic.languages,
                service_area=mechanic.service_area,
                verified=mechanic.verified,
                verification_status=mechanic.verification_status,
                online=mechanic.online,
                last_heartbeat_at=mechanic.last_heartbeat_at,
                rating_avg=mechanic.rating_avg,
                rating_count=mechanic.rating_count,
                version=existing.version + 1,
                rejection_reason=mechanic.rejection_reason,
            )
            self._mechanics[mechanic.id] = saved
            return saved
        self._mechanics[mechanic.id] = mechanic
        return mechanic

    async def set_verification(
        self,
        mechanic_id: str,
        *,
        status: str,
        verified: bool,
        reason: str | None,
        expected_version: int,
    ) -> Mechanic:
        current = self._mechanics.get(mechanic_id)
        if current is None:
            raise NotFound("Mechanic not found.")
        if current.version != expected_version:
            raise Conflict("Profile changed elsewhere. Refresh and try again.")
        updated = Mechanic(
            id=current.id,
            display_name=current.display_name,
            photo_path=current.photo_path,
            years_experience=current.years_experience,
            languages=current.languages,
            service_area=current.service_area,
            verified=verified,
            verification_status=VerificationStatus(status),
            online=False if not verified else current.online,
            last_heartbeat_at=current.last_heartbeat_at,
            rating_avg=current.rating_avg,
            rating_count=current.rating_count,
            version=current.version + 1,
            rejection_reason=reason,
        )
        self._mechanics[mechanic_id] = updated
        return updated

    async def set_availability(self, mechanic_id: str, *, online: bool) -> Mechanic:
        current = self._mechanics.get(mechanic_id)
        if current is None:
            raise NotFound("Mechanic not found.")
        updated = Mechanic(
            id=current.id,
            display_name=current.display_name,
            photo_path=current.photo_path,
            years_experience=current.years_experience,
            languages=current.languages,
            service_area=current.service_area,
            verified=current.verified,
            verification_status=current.verification_status,
            online=online,
            last_heartbeat_at=current.last_heartbeat_at,
            rating_avg=current.rating_avg,
            rating_count=current.rating_count,
            version=current.version + 1,
            rejection_reason=current.rejection_reason,
        )
        self._mechanics[mechanic_id] = updated
        return updated

    async def record_heartbeat(self, mechanic_id: str, *, at: datetime) -> Mechanic:
        current = self._mechanics.get(mechanic_id)
        if current is None:
            raise NotFound("Mechanic not found.")
        now = at
        updated = Mechanic(
            id=current.id,
            display_name=current.display_name,
            photo_path=current.photo_path,
            years_experience=current.years_experience,
            languages=current.languages,
            service_area=current.service_area,
            verified=current.verified,
            verification_status=current.verification_status,
            online=current.online,
            last_heartbeat_at=now,
            rating_avg=current.rating_avg,
            rating_count=current.rating_count,
            version=current.version,
            rejection_reason=current.rejection_reason,
        )
        self._mechanics[mechanic_id] = updated
        return updated

    async def save_document(self, document: MechanicDocument) -> MechanicDocument:
        docs = self._documents.setdefault(document.mechanic_id, [])
        docs.append(document)
        return document

    async def list_documents(self, mechanic_id: str) -> list[MechanicDocument]:
        return list(self._documents.get(mechanic_id, []))

    def seed_draft(self, mechanic_id: str, now: datetime) -> Mechanic:
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
        self._mechanics[mechanic_id] = draft
        return draft
