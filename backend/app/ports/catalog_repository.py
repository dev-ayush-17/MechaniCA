from typing import Protocol

from app.domain.catalog import ServiceDefinition


class CatalogRepository(Protocol):
    async def list_active_services(self) -> list[ServiceDefinition]: ...

    async def get_service(self, code: str) -> ServiceDefinition | None: ...
