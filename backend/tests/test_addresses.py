from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.address_repository import FakeAddressRepository
from app.adapters.fake.auth import FakeAuth
from app.api.deps import (
    address_repository_dep,
    auth_verifier_dep,
    manage_addresses_dep,
    role_claims_dep,
)
from app.application.manage_addresses import ManageAddresses
from app.main import create_app

PHONE = "+919876543210"
UID = "uid_addr"
TOKEN = f"fake:{UID}:{PHONE}"


def _headers(idempotency: str = "11111111-1111-1111-1111-111111111111") -> dict[str, str]:
    return {"Authorization": f"Bearer {TOKEN}", "Idempotency-Key": idempotency}


def _body(**overrides: object) -> dict[str, object]:
    body: dict[str, object] = {
        "label": "Home",
        "line1": "Rajendra Nagar",
        "city": "Patna",
        "pincode": "800001",
        "lat": 25.5941,
        "lng": 85.1376,
    }
    body.update(overrides)
    return body


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.addresses = FakeAddressRepository()
        use_case = ManageAddresses(addresses=self.addresses)
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[address_repository_dep] = lambda: self.addresses
        app.dependency_overrides[manage_addresses_dep] = lambda: use_case
        self.client = TestClient(app)


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_address_requires_pincode(env: _Env) -> None:
    response = env.client.post("/v1/addresses", json=_body(pincode="80001"), headers=_headers())
    assert response.status_code == 400
    assert response.json()["error"]["message"] == "Enter a 6-digit PIN code."


def test_create_address_accepts_valid_pin(env: _Env) -> None:
    response = env.client.post("/v1/addresses", json=_body(), headers=_headers())
    assert response.status_code == 201
    assert response.json()["pincode"] == "800001"
    assert response.json()["isDefault"] is True
