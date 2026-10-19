from typing import Any

from firebase_admin import firestore

from app.domain.catalog import SEED_SERVICES, ServiceDefinition


def _from_doc(code: str, data: dict[str, object]) -> ServiceDefinition:
    return ServiceDefinition(
        code=code,
        name=str(data["name"]),
        description=str(data.get("description", "")),
        base_labor_paise=int(str(data["baseLaborPaise"])),
        duration_min=int(str(data["durationMin"])),
        active=bool(data.get("active", True)),
        sort_order=int(str(data.get("sortOrder", 0))),
    )


def _to_doc(service: ServiceDefinition) -> dict[str, object]:
    return {
        "name": service.name,
        "description": service.description,
        "baseLaborPaise": service.base_labor_paise,
        "durationMin": service.duration_min,
        "active": service.active,
        "sortOrder": service.sort_order,
    }


class FirestoreCatalogRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self) -> Any:
        return self._db.collection("serviceCatalog")

    def _ensure_seeded(self) -> None:
        existing = {snap.id for snap in self._col().stream()}
        for service in SEED_SERVICES:
            if service.code not in existing:
                self._col().document(service.code).set(_to_doc(service))

    async def list_active_services(self) -> list[ServiceDefinition]:
        self._ensure_seeded()
        snaps = self._col().where("active", "==", True).stream()
        items = [_from_doc(s.id, s.to_dict() or {}) for s in snaps]
        return sorted(items, key=lambda s: s.sort_order)

    async def get_service(self, code: str) -> ServiceDefinition | None:
        self._ensure_seeded()
        snap = self._col().document(code).get()
        if not snap.exists:
            return None
        return _from_doc(snap.id, snap.to_dict() or {})
