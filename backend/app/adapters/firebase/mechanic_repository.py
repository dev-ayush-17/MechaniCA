"""Firestore mechanics/{id}. Admin SDK only."""

from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.domain.errors import Conflict, NotFound
from app.domain.geo import haversine_km
from app.domain.mechanic import (
    DocumentKind,
    Mechanic,
    MechanicDocument,
    ServiceArea,
    VerificationStatus,
)


def _parse_time(value: object) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


def _area_to_doc(area: ServiceArea | None) -> dict[str, object] | None:
    if area is None:
        return None
    return {
        "lat": area.lat,
        "lng": area.lng,
        "radiusKm": area.radius_km,
        "geohash": area.geohash,
    }


def _area_from_doc(data: object) -> ServiceArea | None:
    if not isinstance(data, dict):
        return None
    return ServiceArea(
        lat=float(str(data["lat"])),
        lng=float(str(data["lng"])),
        radius_km=float(str(data["radiusKm"])),
        geohash=str(data.get("geohash", "")),
    )


def mechanic_to_doc(mechanic: Mechanic) -> dict[str, object]:
    return {
        "displayName": mechanic.display_name,
        "photoPath": mechanic.photo_path,
        "yearsExperience": mechanic.years_experience,
        "languages": list(mechanic.languages),
        "serviceArea": _area_to_doc(mechanic.service_area),
        "verified": mechanic.verified,
        "verificationStatus": mechanic.verification_status.value,
        "online": mechanic.online,
        "lastHeartbeatAt": mechanic.last_heartbeat_at,
        "ratingAvg": mechanic.rating_avg,
        "ratingCount": mechanic.rating_count,
        "version": mechanic.version,
        "rejectionReason": mechanic.rejection_reason,
    }


def mechanic_from_doc(mechanic_id: str, data: dict[str, object]) -> Mechanic:
    raw_languages = data.get("languages")
    languages = (
        tuple(str(item) for item in raw_languages) if isinstance(raw_languages, list) else ()
    )
    return Mechanic(
        id=mechanic_id,
        display_name=str(data.get("displayName", "")),
        photo_path=str(data.get("photoPath", "")),
        years_experience=int(str(data.get("yearsExperience", 0))),
        languages=languages,
        service_area=_area_from_doc(data.get("serviceArea")),
        verified=bool(data.get("verified", False)),
        verification_status=VerificationStatus(str(data.get("verificationStatus", "draft"))),
        online=bool(data.get("online", False)),
        last_heartbeat_at=_parse_time(data.get("lastHeartbeatAt")),
        rating_avg=float(str(data.get("ratingAvg", 0))),
        rating_count=int(str(data.get("ratingCount", 0))),
        version=int(str(data.get("version", 1))),
        rejection_reason=str(data["rejectionReason"]) if data.get("rejectionReason") else None,
    )


class FirestoreMechanicRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self) -> Any:
        return self._db.collection("mechanics")

    async def get(self, mechanic_id: str) -> Mechanic | None:
        snap = self._col().document(mechanic_id).get()
        if not snap.exists:
            return None
        return mechanic_from_doc(snap.id, snap.to_dict() or {})

    async def save_profile(self, mechanic: Mechanic) -> Mechanic:
        ref = self._col().document(mechanic.id)
        snap = ref.get()
        if snap.exists:
            current = mechanic_from_doc(snap.id, snap.to_dict() or {})
            if current.version != mechanic.version:
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
                version=current.version + 1,
                rejection_reason=mechanic.rejection_reason,
            )
        else:
            saved = mechanic
        ref.set(mechanic_to_doc(saved))
        return saved

    async def set_verification(
        self,
        mechanic_id: str,
        *,
        status: str,
        verified: bool,
        reason: str | None,
        expected_version: int,
    ) -> Mechanic:
        current = await self.get(mechanic_id)
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
        self._col().document(mechanic_id).set(mechanic_to_doc(updated))
        return updated

    async def set_availability(self, mechanic_id: str, *, online: bool) -> Mechanic:
        current = await self.get(mechanic_id)
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
        self._col().document(mechanic_id).set(mechanic_to_doc(updated))
        return updated

    async def record_heartbeat(self, mechanic_id: str, *, at: datetime) -> Mechanic:
        current = await self.get(mechanic_id)
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
            online=current.online,
            last_heartbeat_at=at,
            rating_avg=current.rating_avg,
            rating_count=current.rating_count,
            version=current.version,
            rejection_reason=current.rejection_reason,
        )
        self._col().document(mechanic_id).set(mechanic_to_doc(updated))
        return updated

    async def save_document(self, document: MechanicDocument) -> MechanicDocument:
        self._col().document(document.mechanic_id).collection("documents").document(document.id).set(
            {
                "mechanicId": document.mechanic_id,
                "kind": document.kind.value,
                "storagePath": document.storage_path,
                "uploadedAt": document.uploaded_at,
            }
        )
        return document

    async def list_documents(self, mechanic_id: str) -> list[MechanicDocument]:
        snaps = self._col().document(mechanic_id).collection("documents").stream()
        docs: list[MechanicDocument] = []
        for snap in snaps:
            data = snap.to_dict() or {}
            uploaded = _parse_time(data.get("uploadedAt"))
            if uploaded is None:
                continue
            docs.append(
                MechanicDocument(
                    id=snap.id,
                    mechanic_id=mechanic_id,
                    kind=_document_kind(str(data.get("kind", "licence"))),
                    storage_path=str(data.get("storagePath", "")),
                    uploaded_at=uploaded,
                )
            )
        return docs

    async def find_online_near(
        self, lat: float, lng: float, radius_km: float, limit: int
    ) -> list[Mechanic]:
        found: list[tuple[float, Mechanic]] = []
        for snap in self._col().stream():
            mechanic = mechanic_from_doc(snap.id, snap.to_dict() or {})
            if not mechanic.verified or not mechanic.online or mechanic.service_area is None:
                continue
            distance = haversine_km(lat, lng, mechanic.service_area.lat, mechanic.service_area.lng)
            if distance <= radius_km:
                found.append((distance, mechanic))
        found.sort(key=lambda item: item[0])
        return [mechanic for _, mechanic in found[:limit]]

    async def list_pending(self) -> list[Mechanic]:
        pending: list[Mechanic] = []
        for snap in self._col().stream():
            mechanic = mechanic_from_doc(snap.id, snap.to_dict() or {})
            if mechanic.verification_status is VerificationStatus.PENDING:
                pending.append(mechanic)
        return pending


def _document_kind(value: str) -> DocumentKind:
    try:
        return DocumentKind(value)
    except ValueError:
        return DocumentKind.LICENCE
