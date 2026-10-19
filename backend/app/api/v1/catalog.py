from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import catalog_repository_dep, principal_dep
from app.api.errors import error_responses
from app.domain.catalog import ServiceDefinition
from app.domain.user import Principal
from app.ports.catalog_repository import CatalogRepository

router = APIRouter(prefix="/v1/catalog", tags=["catalog"], responses=error_responses(400, 401, 403))


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class ServiceOut(_Camel):
    code: str
    name: str
    description: str
    base_labor_paise: int
    duration_min: int
    active: bool
    sort_order: int

    @classmethod
    def of(cls, service: ServiceDefinition) -> "ServiceOut":
        return cls(
            code=service.code,
            name=service.name,
            description=service.description,
            base_labor_paise=service.base_labor_paise,
            duration_min=service.duration_min,
            active=service.active,
            sort_order=service.sort_order,
        )


class ServiceListOut(_Camel):
    items: list[ServiceOut]


@router.get("/services", response_model=ServiceListOut)
async def list_services(
    _principal: Annotated[Principal, Depends(principal_dep)],
    catalog: Annotated[CatalogRepository, Depends(catalog_repository_dep)],
) -> ServiceListOut:
    items = await catalog.list_active_services()
    return ServiceListOut(items=[ServiceOut.of(s) for s in items])
