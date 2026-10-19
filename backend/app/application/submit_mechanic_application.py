from dataclasses import dataclass
from uuid import uuid4

from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.geo import geohash_encode
from app.domain.mechanic import (
    DocumentKind,
    Mechanic,
    MechanicDocument,
    ServiceArea,
    VerificationStatus,
)
from app.domain.user import Principal, Role
from app.ports.clock import Clock
from app.ports.mechanic_repository import MechanicRepository


@dataclass(frozen=True)
class DocumentInput:
    kind: DocumentKind
    storage_path: str


@dataclass(frozen=True)
class ServiceAreaInput:
    lat: float
    lng: float
    radius_km: float


@dataclass(frozen=True)
class SubmitMechanicApplication:
    mechanics: MechanicRepository
    clock: Clock

    async def execute(
        self,
        principal: Principal,
        *,
        display_name: str,
        photo_path: str,
        years_experience: int,
        languages: list[str],
        service_area: ServiceAreaInput,
        documents: list[DocumentInput],
    ) -> Mechanic:
        if principal.role != Role.MECHANIC:
            raise PermissionDenied("Mechanic account required.")
        current = await self.mechanics.get(principal.user_id)
        if current is None:
            raise NotFound("Finish mechanic setup first.")
        if current.verification_status == VerificationStatus.PENDING:
            raise InvalidInput("Your application is already under review.")
        if current.verification_status == VerificationStatus.APPROVED:
            raise InvalidInput("You are already verified.")

        name = display_name.strip()
        if len(name) < 2 or len(name) > 40:
            raise InvalidInput(
                "Display name must be 2–40 characters.", fields={"displayName": "invalid"}
            )
        if not photo_path.strip():
            raise InvalidInput("Add a profile photo.", fields={"photoPath": "required"})
        if years_experience < 0 or years_experience > 50:
            raise InvalidInput("Years must be 0–50.", fields={"yearsExperience": "invalid"})
        if not languages:
            raise InvalidInput("Pick at least one language.", fields={"languages": "required"})
        if service_area.radius_km < 1 or service_area.radius_km > 20:
            raise InvalidInput(
                "Radius must be 1–20 km.", fields={"serviceArea.radiusKm": "invalid"}
            )

        kinds = {DocumentKind.LICENCE, DocumentKind.GOVERNMENT_ID, DocumentKind.SELFIE}
        provided = {doc.kind for doc in documents}
        if provided != kinds:
            raise InvalidInput(
                "Upload licence, government ID, and a selfie.",
                fields={"documents": "incomplete"},
            )
        for doc in documents:
            prefix = f"mechanicDocs/{principal.user_id}/{doc.kind.value}/"
            if not doc.storage_path.startswith(prefix):
                raise InvalidInput(
                    "Document path does not match the upload.",
                    fields={"documents": "invalid_path"},
                )

        area = ServiceArea(
            lat=service_area.lat,
            lng=service_area.lng,
            radius_km=service_area.radius_km,
            geohash=geohash_encode(service_area.lat, service_area.lng),
        )
        now = self.clock.now()
        for doc in documents:
            await self.mechanics.save_document(
                MechanicDocument(
                    id=uuid4().hex,
                    mechanic_id=principal.user_id,
                    kind=doc.kind,
                    storage_path=doc.storage_path,
                    uploaded_at=now,
                )
            )

        updated = Mechanic(
            id=current.id,
            display_name=name,
            photo_path=photo_path.strip(),
            years_experience=years_experience,
            languages=tuple(languages),
            service_area=area,
            verified=False,
            verification_status=VerificationStatus.PENDING,
            online=False,
            last_heartbeat_at=current.last_heartbeat_at,
            rating_avg=current.rating_avg,
            rating_count=current.rating_count,
            version=current.version,
            rejection_reason=None,
        )
        return await self.mechanics.save_profile(updated)
