from dataclasses import replace

from app.domain.catalog import SEED_SERVICES, ServiceDefinition


class FakeCatalogRepository:
    """In-memory catalog. Seeds the five PRD services. Tests may deactivate."""

    def __init__(self, services: tuple[ServiceDefinition, ...] | None = None) -> None:
        self._services: dict[str, ServiceDefinition] = {
            item.code: item for item in (services or SEED_SERVICES)
        }
        self.writes: list[str] = []

    async def list_active_services(self) -> list[ServiceDefinition]:
        active = [s for s in self._services.values() if s.active]
        return sorted(active, key=lambda s: s.sort_order)

    async def get_service(self, code: str) -> ServiceDefinition | None:
        return self._services.get(code)

    def deactivate(self, code: str) -> None:
        current = self._services[code]
        self._services[code] = replace(current, active=False)
        self.writes.append(f"deactivate:{code}")
