from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.api.deps import (
    auth_verifier_dep,
    manage_vehicles_dep,
    role_claims_dep,
    vehicle_repository_dep,
)
from app.application.manage_vehicles import ManageVehicles
from app.main import create_app

PHONE = "+919876543210"
UID = "uid_veh"
TOKEN = f"fake:{UID}:{PHONE}"


def _headers(idempotency: str = "11111111-1111-1111-1111-111111111111") -> dict[str, str]:
    return {
        "Authorization": f"Bearer {TOKEN}",
        "Idempotency-Key": idempotency,
    }


def _vehicle_body(**overrides: object) -> dict[str, object]:
    body: dict[str, object] = {
        "vehicleType": "two_wheeler",
        "brand": "TVS",
        "model": "Apache",
        "year": 2022,
        "registrationNumber": "BR01AB1234",
        "fuelType": "petrol",
        "color": "Black",
        "odometerKm": 1000,
        "isPrimary": True,
    }
    body.update(overrides)
    return body


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.vehicles = FakeVehicleRepository()
        self.clock = FakeClock(datetime(2026, 1, 1, tzinfo=UTC))
        use_case = ManageVehicles(vehicles=self.vehicles, clock=self.clock)
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[vehicle_repository_dep] = lambda: self.vehicles
        app.dependency_overrides[manage_vehicles_dep] = lambda: use_case
        self.client = TestClient(app)


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_create_rejects_invalid_plate(env: _Env) -> None:
    response = env.client.post(
        "/v1/vehicles",
        json=_vehicle_body(registrationNumber="BR80Y 024"),
        headers=_headers(),
    )
    assert response.status_code == 400
    assert response.json()["error"]["message"] == "Enter a valid registration number."


def test_second_primary_unsets_the_first(env: _Env) -> None:
    first = env.client.post(
        "/v1/vehicles", json=_vehicle_body(isPrimary=True), headers=_headers("key-1")
    )
    second = env.client.post(
        "/v1/vehicles",
        json=_vehicle_body(registrationNumber="BR02CD5678", isPrimary=True),
        headers=_headers("key-2"),
    )
    assert first.status_code == 201
    assert second.status_code == 201
    listed = env.client.get("/v1/vehicles", headers={"Authorization": f"Bearer {TOKEN}"}).json()
    primaries = [v for v in listed["items"] if v["isPrimary"]]
    assert len(primaries) == 1
    assert primaries[0]["id"] == second.json()["id"]
    first_id = first.json()["id"]
    first_row = next(v for v in listed["items"] if v["id"] == first_id)
    assert first_row["isPrimary"] is False


def test_post_requires_idempotency_key(env: _Env) -> None:
    response = env.client.post(
        "/v1/vehicles",
        json=_vehicle_body(),
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    assert response.status_code == 400
