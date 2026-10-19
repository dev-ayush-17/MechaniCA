from dataclasses import dataclass

from app.domain.catalog import PriceQuote, QuoteInput
from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.pricing import PricingService
from app.domain.user import Principal, Role
from app.ports.catalog_repository import CatalogRepository
from app.ports.vehicle_repository import VehicleRepository


@dataclass(frozen=True)
class CreateQuote:
    """Price a service. Does not create a booking or write money."""

    catalog: CatalogRepository
    vehicles: VehicleRepository
    pricing: PricingService

    async def execute(
        self,
        principal: Principal,
        *,
        service_code: str,
        vehicle_id: str,
        coupon_code: str,
    ) -> PriceQuote:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        code = coupon_code.strip()
        if code:
            raise InvalidInput("Coupons arrive in M10.")
        service = await self.catalog.get_service(service_code)
        if service is None:
            raise NotFound("We could not find that service.")
        if not service.active:
            raise InvalidInput("This service is not available.")
        vehicle = await self.vehicles.get(vehicle_id, principal.user_id)
        if vehicle is None:
            raise NotFound("We could not find that vehicle.")
        return self.pricing.quote(QuoteInput(service=service, vehicle_type=vehicle.vehicle_type))
