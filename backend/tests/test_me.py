import logging
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.user_repository import FakeUserRepository
from app.api.deps import auth_verifier_dep, role_claims_dep, user_repository_dep
from app.core.config import Settings
from app.domain.errors import Unauthenticated
from app.domain.user import Role
from app.main import create_app

PHONE = "+919876543210"
UID = "uid_1"
TOKEN = f"fake:{UID}:{PHONE}"


def _headers(token: str = TOKEN) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.users = FakeUserRepository()
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[user_repository_dep] = lambda: self.users
        self.client = TestClient(app)


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_bootstrap_is_idempotent(env: _Env) -> None:
    first = env.client.post(
        "/v1/me/bootstrap", json={"intent": "customer", "name": "Asha"}, headers=_headers()
    )
    second = env.client.post(
        "/v1/me/bootstrap", json={"intent": "customer", "name": "Other"}, headers=_headers()
    )

    assert first.status_code == 201
    assert second.status_code == 200
    assert second.json() == first.json()
    assert second.json()["name"] == "Asha"
    assert second.json()["phoneE164"] == PHONE


def test_role_defaults_to_customer_and_sets_the_claim(env: _Env) -> None:
    response = env.client.post("/v1/me/bootstrap", json={"intent": "customer"}, headers=_headers())

    assert response.json()["role"] == "customer"
    principal = env.client.get("/v1/me", headers=_headers()).json()
    assert principal["role"] == "customer"


def test_client_supplied_role_is_ignored(env: _Env) -> None:
    response = env.client.post(
        "/v1/me/bootstrap", json={"intent": "customer", "role": "admin"}, headers=_headers()
    )

    assert response.status_code == 201
    assert response.json()["role"] == "customer"


def test_unknown_intent_is_rejected(env: _Env) -> None:
    response = env.client.post("/v1/me/bootstrap", json={"intent": "admin"}, headers=_headers())

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_input"


def test_mechanic_intent_sets_mechanic_role(env: _Env) -> None:
    response = env.client.post("/v1/me/bootstrap", json={"intent": "mechanic"}, headers=_headers())

    assert response.json()["role"] == "mechanic"


def test_second_intent_is_role_exists(env: _Env) -> None:
    env.client.post("/v1/me/bootstrap", json={"intent": "customer"}, headers=_headers())
    response = env.client.post("/v1/me/bootstrap", json={"intent": "mechanic"}, headers=_headers())

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "role_exists"


def test_stale_claim_is_refreshed_from_the_document(env: _Env) -> None:
    env.client.post("/v1/me/bootstrap", json={"intent": "mechanic"}, headers=_headers())
    env.auth._claims[UID] = Role.CUSTOMER  # claim drifted from the document

    env.client.post("/v1/me/bootstrap", json={"intent": "mechanic"}, headers=_headers())

    assert env.auth._claims[UID] == Role.MECHANIC


def test_missing_token_is_401(env: _Env) -> None:
    response = env.client.get("/v1/me")

    assert response.status_code == 401
    body = response.json()["error"]
    assert body["code"] == "unauthenticated"
    assert body["requestId"] == response.headers["X-Request-Id"]


@pytest.mark.parametrize("header", ["Basic abc", "Bearer", "Bearer not-a-token", "fake:x:y"])
def test_invalid_token_is_401(env: _Env, header: str) -> None:
    response = env.client.post(
        "/v1/me/bootstrap", json={"intent": "customer"}, headers={"Authorization": header}
    )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthenticated"


def test_me_is_404_before_bootstrap(env: _Env) -> None:
    response = env.client.get("/v1/me", headers=_headers())

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"


def test_tokens_are_not_logged(env: _Env, caplog: pytest.LogCaptureFixture) -> None:
    with caplog.at_level(logging.DEBUG):
        env.client.post("/v1/me/bootstrap", json={"intent": "customer"}, headers=_headers())
        env.client.get("/v1/me", headers=_headers("fake:bad"))

    assert TOKEN not in caplog.text
    assert "fake:bad" not in caplog.text


def test_prod_config_rejects_fake_auth() -> None:
    with pytest.raises(ValidationError):
        Settings(_env_file=None, app_env="prod", provider_auth="fake")  # type: ignore[call-arg]
    with pytest.raises(ValidationError):
        Settings(_env_file=None, app_env="staging", provider_auth="fake")  # type: ignore[call-arg]
    Settings(_env_file=None, app_env="dev", provider_auth="fake")  # type: ignore[call-arg]


def test_fake_auth_cannot_be_built_for_prod() -> None:
    with pytest.raises(ValueError, match="dev or test"):
        FakeAuth("prod")


def test_firebase_provider_needs_a_project_id() -> None:
    with pytest.raises(ValidationError):
        Settings(_env_file=None, app_env="prod", provider_auth="firebase")  # type: ignore[call-arg]


async def test_fake_verifier_raises_typed_error() -> None:
    with pytest.raises(Unauthenticated):
        await FakeAuth("test").verify("garbage")
