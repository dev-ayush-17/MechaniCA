from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.audit_log import FakeAuditLog
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.user_repository import FakeUserRepository
from app.api.deps import (
    audit_log_dep,
    auth_verifier_dep,
    mechanic_repository_dep,
    role_claims_dep,
    user_repository_dep,
)
from app.domain.user import Role
from app.main import create_app

MECH_PHONE = "+919876543211"
MECH_UID = "mech_uid"
MECH_TOKEN = f"fake:{MECH_UID}:{MECH_PHONE}"
ADMIN_UID = "admin_uid"
ADMIN_PHONE = "+919876543212"
ADMIN_TOKEN = f"fake:{ADMIN_UID}:{ADMIN_PHONE}"


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _application_body(uid: str) -> dict:
    base = f"mechanicDocs/{uid}"
    return {
        "displayName": "Imran Khan",
        "photoPath": f"{base}/photo/profile.jpg",
        "yearsExperience": 5,
        "languages": ["en", "hi"],
        "serviceArea": {"lat": 28.6139, "lng": 77.209, "radiusKm": 10},
        "documents": [
            {"kind": "licence", "storagePath": f"{base}/licence/a.pdf"},
            {"kind": "government_id", "storagePath": f"{base}/government_id/b.pdf"},
            {"kind": "selfie", "storagePath": f"{base}/selfie/c.jpg"},
        ],
    }


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.users = FakeUserRepository()
        self.mechanics = FakeMechanicRepository()
        self.audit = FakeAuditLog()
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[user_repository_dep] = lambda: self.users
        app.dependency_overrides[mechanic_repository_dep] = lambda: self.mechanics
        app.dependency_overrides[audit_log_dep] = lambda: self.audit
        self.client = TestClient(app)

    def bootstrap_mechanic(self) -> None:
        self.auth._claims[MECH_UID] = Role.MECHANIC
        r = self.client.post(
            "/v1/me/bootstrap", json={"intent": "mechanic"}, headers=_headers(MECH_TOKEN)
        )
        assert r.status_code == 201

    def bootstrap_admin(self) -> None:
        self.auth._claims[ADMIN_UID] = Role.ADMIN


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def _submit_application(env: _Env) -> None:
    env.client.post(
        "/v1/mechanic/application",
        json=_application_body(MECH_UID),
        headers=_headers(MECH_TOKEN),
    )


def test_unverified_mechanic_cannot_go_online(env: _Env) -> None:
    env.bootstrap_mechanic()
    _submit_application(env)
    response = env.client.post(
        "/v1/mechanic/availability", json={"online": True}, headers=_headers(MECH_TOKEN)
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_input"


def test_approve_sets_verified_and_audit(env: _Env) -> None:
    env.bootstrap_mechanic()
    env.bootstrap_admin()
    _submit_application(env)
    approve = env.client.post(
        f"/v1/admin/mechanics/{MECH_UID}/verification",
        json={"decision": "approve"},
        headers=_headers(ADMIN_TOKEN),
    )
    assert approve.status_code == 200
    body = approve.json()
    assert body["verified"] is True
    assert body["verificationStatus"] == "approved"
    assert env.auth._mechanic_verified.get(MECH_UID) is True
    assert len(env.audit.events) == 1
    assert env.audit.events[0].action == "mechanic_verification_approve"

    online = env.client.post(
        "/v1/mechanic/availability", json={"online": True}, headers=_headers(MECH_TOKEN)
    )
    assert online.status_code == 200
    assert online.json()["online"] is True


def test_reject_requires_a_reason(env: _Env) -> None:
    env.bootstrap_mechanic()
    env.bootstrap_admin()
    _submit_application(env)
    response = env.client.post(
        f"/v1/admin/mechanics/{MECH_UID}/verification",
        json={"decision": "reject"},
        headers=_headers(ADMIN_TOKEN),
    )
    assert response.status_code == 400
    assert response.json()["error"]["fields"]["reason"] == "required"


def test_signed_upload_rejects_parent_directory(env: _Env) -> None:
    env.bootstrap_mechanic()
    bad = env.client.post(
        "/v1/uploads/sign",
        json={
            "path": f"mechanicDocs/{MECH_UID}/../other/secret.pdf",
            "contentType": "application/pdf",
            "maxBytes": 1000,
        },
        headers=_headers(MECH_TOKEN),
    )
    assert bad.status_code in (400, 403)


def test_reject_writes_audit(env: _Env) -> None:
    env.bootstrap_mechanic()
    env.bootstrap_admin()
    _submit_application(env)
    response = env.client.post(
        f"/v1/admin/mechanics/{MECH_UID}/verification",
        json={"decision": "reject", "reason": "Blurry licence photo"},
        headers=_headers(ADMIN_TOKEN),
    )
    assert response.status_code == 200
    assert len(env.audit.events) == 1
    assert env.audit.events[0].action == "mechanic_verification_reject"


def test_heartbeat_requires_online(env: _Env) -> None:
    env.bootstrap_mechanic()
    off = env.client.post("/v1/mechanic/heartbeat", headers=_headers(MECH_TOKEN))
    assert off.status_code == 400
