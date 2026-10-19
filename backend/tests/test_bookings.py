from collections.abc import Iterator
from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.address_repository import FakeAddressRepository
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.catalog_repository import FakeCatalogRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.idempotency_store import FakeIdempotencyStore
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.api.deps import (
    address_repository_dep,
    auth_verifier_dep,
    booking_repository_dep,
    cancel_booking_dep,
    catalog_repository_dep,
    clock_dep,
    create_booking_dep,
    get_booking_dep,
    idempotency_store_dep,
    role_claims_dep,
    transition_booking_dep,
    vehicle_repository_dep,
)
from app.application.cancel_booking import CancelBooking
from app.application.create_booking import CreateBooking
from app.application.get_booking import GetBooking
from app.application.transition_booking import TransitionBooking
from app.domain.booking import BookingPolicy
from app.domain.booking_state import BookingStatus
from app.domain.catalog import DEFAULT_PRICING_CONFIG
from app.domain.pricing import PricingService
from app.domain.vehicle import Vehicle, VehicleType
from app.main import create_app

PHONE = "+919876543210"
UID = "uid_book"
TOKEN = f"fake:{UID}:{PHONE}"
VEHICLE_ID = "veh_book_1"
KEY = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
KEY_B = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"


def _headers(key: str = KEY) -> dict[str, str]:
    return {"Authorization": f"Bearer {TOKEN}", "Idempotency-Key": key}


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


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.catalog = FakeCatalogRepository()
        self.vehicles = FakeVehicleRepository()
        self.bookings = FakeBookingRepository()
        self.addresses = FakeAddressRepository()
        self.idempotency = FakeIdempotencyStore()
        self.clock = FakeClock(datetime(2026, 6, 1, 10, 0, tzinfo=UTC))
        self.policy = BookingPolicy()
        _seed_vehicle(self.vehicles)
        pricing = PricingService(DEFAULT_PRICING_CONFIG)
        create = CreateBooking(
            catalog=self.catalog,
            vehicles=self.vehicles,
            bookings=self.bookings,
            addresses=self.addresses,
            idempotency=self.idempotency,
            pricing=pricing,
            clock=self.clock,
            policy=self.policy,
        )
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[catalog_repository_dep] = lambda: self.catalog
        app.dependency_overrides[vehicle_repository_dep] = lambda: self.vehicles
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[address_repository_dep] = lambda: self.addresses
        app.dependency_overrides[idempotency_store_dep] = lambda: self.idempotency
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[create_booking_dep] = lambda: create
        app.dependency_overrides[cancel_booking_dep] = lambda: CancelBooking(
            bookings=self.bookings, clock=self.clock, policy=self.policy
        )
        app.dependency_overrides[transition_booking_dep] = lambda: TransitionBooking(
            bookings=self.bookings, clock=self.clock
        )
        app.dependency_overrides[get_booking_dep] = lambda: GetBooking(self.bookings)
        self.client = TestClient(app)

    def create(self, key: str = KEY, **overrides: object):
        body: dict[str, object] = {
            "vehicleId": VEHICLE_ID,
            "serviceCode": "general_service",
            "addressId": "addr_home",
            "mode": "instant",
            "urgency": "normal",
            "paymentMethod": "upi",
        }
        body.update(overrides)
        return self.client.post("/v1/bookings", json=body, headers=_headers(key))


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_booking_create_is_idempotent(env: _Env) -> None:
    first = env.create()
    second = env.create()
    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["id"] == second.json()["id"]
    assert len(env.bookings.bookings) == 1


def test_booking_in_progress_conflict(env: _Env) -> None:
    first = env.create()
    assert first.status_code == 201
    second = env.create(KEY_B)
    assert second.status_code == 409
    assert second.json()["error"]["code"] == "booking_in_progress"


def test_scheduled_window_too_soon(env: _Env) -> None:
    start = env.clock.now() + timedelta(minutes=30)
    response = env.create(
        scheduledStart=start.isoformat().replace("+00:00", "Z"),
        mode="scheduled",
    )
    assert response.status_code == 400
    assert "90 minutes" in response.json()["error"]["message"]


def test_sos_sets_urgency(env: _Env) -> None:
    response = env.create(urgency="sos", serviceCode="general_service")
    assert response.status_code == 201
    body = response.json()
    assert body["urgency"] == "sos"
    assert body["mode"] == "instant"
    assert body["serviceCode"] == "breakdown"


def test_enroute_cancel_records_fee(env: _Env) -> None:
    created = env.create()
    booking_id = created.json()["id"]
    stored = env.bookings.bookings[booking_id]
    env.bookings.bookings[booking_id] = stored.with_status(
        BookingStatus.EN_ROUTE, now=env.clock.now(), mechanic_id="mech_1"
    )
    response = env.client.post(
        f"/v1/bookings/{booking_id}/cancel",
        json={"reason": "Changed plans"},
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "cancelled"
    assert body["cancelFeePaise"] == 9900


def test_missing_idempotency_key(env: _Env) -> None:
    response = env.client.post(
        "/v1/bookings",
        json={
            "vehicleId": VEHICLE_ID,
            "serviceCode": "general_service",
            "addressId": "addr_home",
            "mode": "instant",
            "paymentMethod": "upi",
        },
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "idempotency_key_required"


def test_idempotency_conflict_different_body(env: _Env) -> None:
    first = env.create()
    assert first.status_code == 201
    second = env.create(serviceCode="oil_change")
    assert second.status_code == 409
    assert second.json()["error"]["code"] == "idempotency_conflict"
