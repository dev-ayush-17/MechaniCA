from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.catalog_repository import FakeCatalogRepository
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.api.deps import (
    auth_verifier_dep,
    catalog_repository_dep,
    create_quote_dep,
    role_claims_dep,
    vehicle_repository_dep,
)
from app.application.create_quote import CreateQuote
from app.domain.catalog import DEFAULT_PRICING_CONFIG
from app.domain.pricing import PricingService
from app.domain.vehicle import Vehicle, VehicleType
from app.main import create_app

PHONE = "+919876543210"
UID = "uid_quote"
TOKEN = f"fake:{UID}:{PHONE}"
VEHICLE_ID = "veh_quote_1"


def _headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {TOKEN}"}


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
        self.bookings: list[object] = []
        _seed_vehicle(self.vehicles)
        pricing = PricingService(DEFAULT_PRICING_CONFIG)
        use_case = CreateQuote(catalog=self.catalog, vehicles=self.vehicles, pricing=pricing)
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[catalog_repository_dep] = lambda: self.catalog
        app.dependency_overrides[vehicle_repository_dep] = lambda: self.vehicles
        app.dependency_overrides[create_quote_dep] = lambda: use_case
        self.client = TestClient(app)


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_quote_general_service_bike(env: _Env) -> None:
    response = env.client.post(
        "/v1/quotes",
        json={"vehicleId": VEHICLE_ID, "serviceCode": "general_service"},
        headers=_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["laborPaise"] == 59900
    assert body["feePaise"] == 4900
    assert body["cgstPaise"] == 5832
    assert body["sgstPaise"] == 5832
    assert body["totalPaise"] == 76464


def test_inactive_service_is_rejected(env: _Env) -> None:
    env.catalog.deactivate("oil_change")
    env.catalog.writes.clear()
    response = env.client.post(
        "/v1/quotes",
        json={"vehicleId": VEHICLE_ID, "serviceCode": "oil_change"},
        headers=_headers(),
    )
    assert response.status_code == 400
    error = response.json()["error"]
    assert error["code"] == "invalid_input"
    assert "not available" in error["message"].lower()


def test_quote_does_not_write_a_booking(env: _Env) -> None:
    writes_before = list(env.catalog.writes)
    first = env.client.post(
        "/v1/quotes",
        json={"vehicleId": VEHICLE_ID, "serviceCode": "general_service"},
        headers=_headers(),
    )
    second = env.client.post(
        "/v1/quotes",
        json={"vehicleId": VEHICLE_ID, "serviceCode": "general_service"},
        headers=_headers(),
    )
    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json() == second.json()
    assert env.catalog.writes == writes_before
    assert env.bookings == []
    listed = env.client.get("/v1/bookings", headers=_headers())
    assert listed.status_code == 200
    assert listed.json()["items"] == []


def test_empty_coupon_is_no_discount(env: _Env) -> None:
    response = env.client.post(
        "/v1/quotes",
        json={
            "vehicleId": VEHICLE_ID,
            "serviceCode": "general_service",
            "couponCode": "",
        },
        headers=_headers(),
    )
    assert response.status_code == 200
    assert response.json()["discountPaise"] == 0


def test_non_empty_coupon_waits_for_m10(env: _Env) -> None:
    response = env.client.post(
        "/v1/quotes",
        json={
            "vehicleId": VEHICLE_ID,
            "serviceCode": "general_service",
            "couponCode": "FLAT50",
        },
        headers=_headers(),
    )
    assert response.status_code == 400
    assert response.json()["error"]["message"] == "Coupons arrive in M10."


def test_catalog_lists_five_seed_services(env: _Env) -> None:
    response = env.client.get("/v1/catalog/services", headers=_headers())
    assert response.status_code == 200
    codes = [item["code"] for item in response.json()["items"]]
    assert codes == [
        "general_service",
        "oil_change",
        "engine_issue",
        "brake_repair",
        "breakdown",
    ]
