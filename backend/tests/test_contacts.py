from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.user_repository import FakeUserRepository
from app.api.deps import (
    auth_verifier_dep,
    manage_contacts_dep,
    role_claims_dep,
    user_repository_dep,
)
from app.application.manage_contacts import ManageContacts
from app.main import create_app

PHONE = "+919876543210"
UID = "uid_con"
TOKEN = f"fake:{UID}:{PHONE}"


def _headers() -> dict[str, str]:
    return {"Authorization": f"Bearer {TOKEN}"}


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.users = FakeUserRepository()
        use_case = ManageContacts(users=self.users)
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[user_repository_dep] = lambda: self.users
        app.dependency_overrides[manage_contacts_dep] = lambda: use_case
        self.client = TestClient(app)


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_max_three_emergency_contacts(env: _Env) -> None:
    for index, mobile in enumerate(("9876543210", "9876543211", "9876543212"), start=1):
        created = env.client.post(
            "/v1/me/contacts",
            json={"name": f"Contact {index}", "phone": mobile},
            headers=_headers(),
        )
        assert created.status_code == 201
    fourth = env.client.post(
        "/v1/me/contacts",
        json={"name": "Contact 4", "phone": "9876543213"},
        headers=_headers(),
    )
    assert fourth.status_code == 400
    assert fourth.json()["error"]["message"] == "You can save up to 3 emergency contacts."
