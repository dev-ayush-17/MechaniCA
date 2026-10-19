from datetime import UTC, datetime

import pytest

from app.adapters.fake.address_repository import FakeAddressRepository
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.catalog_repository import FakeCatalogRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.idempotency_store import FakeIdempotencyStore
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.application.create_booking import CreateBooking
from app.domain.booking import BookingMode, BookingPolicy, PaymentMethod, Urgency
from app.domain.catalog import DEFAULT_PRICING_CONFIG
from app.domain.pricing import PricingService
from app.domain.user import Principal, Role
from app.domain.vehicle import Vehicle, VehicleType

UID = "uid_create"
KEY = "11111111-1111-1111-1111-111111111111"
VEHICLE_ID = "veh_1"


def _principal() -> Principal:
    return Principal(user_id=UID, role=Role.CUSTOMER, phone_e164="+919876543210")


def _seed_vehicle(repo: FakeVehicleRepository) -> None:
    now = datetime(2026, 1, 1, tzinfo=UTC)
    repo._by_owner[UID] = {
        VEHICLE_ID: Vehicle(
            id=VEHICLE_ID,
            owner_id=UID,
            vehicle_type=VehicleType.TWO_WHEELER,
            brand="TVS",
            model="Apache",
            year=2022,
            registration_number="BR01AB1234",
            fuel_type="petrol",
            color="Black",
            odometer_km=1000,
            is_primary=True,
            created_at=now,
            updated_at=now,
            version=1,
        )
    }


def _use_case() -> CreateBooking:
    vehicles = FakeVehicleRepository()
    _seed_vehicle(vehicles)
    return CreateBooking(
        catalog=FakeCatalogRepository(),
        vehicles=vehicles,
        bookings=FakeBookingRepository(),
        addresses=FakeAddressRepository(),
        idempotency=FakeIdempotencyStore(),
        pricing=PricingService(DEFAULT_PRICING_CONFIG),
        clock=FakeClock(datetime(2026, 6, 1, 10, 0, tzinfo=UTC)),
        policy=BookingPolicy(),
    )


async def _create(use_case: CreateBooking, **overrides: object):
    fields = {
        "idempotency_key": KEY,
        "vehicle_id": VEHICLE_ID,
        "service_code": "general_service",
        "address_id": "addr_home",
        "mode": BookingMode.INSTANT,
        "urgency": Urgency.NORMAL,
        "payment_method": PaymentMethod.UPI,
    }
    fields.update(overrides)
    return await use_case.execute(_principal(), **fields)  # type: ignore[arg-type]


@pytest.mark.asyncio
async def test_booking_create_is_idempotent() -> None:
    use_case = _use_case()
    first = await _create(use_case)
    second = await _create(use_case)
    assert first.id == second.id
    assert len(use_case.bookings.bookings) == 1
    assert first.status.value == "confirmed"
    assert first.labor_paise == 59900
