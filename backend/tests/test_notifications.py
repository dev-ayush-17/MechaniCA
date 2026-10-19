from collections.abc import Iterator
from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.notification_repository import FakeNotificationRepository
from app.api.deps import (
    auth_verifier_dep,
    clock_dep,
    manage_notifications_dep,
    notification_repository_dep,
    role_claims_dep,
)
from app.application.manage_notifications import ManageNotifications
from app.domain.notification import InAppNotification
from app.domain.user import Role
from app.main import create_app

OWNER_UID = "uid_owner"
OTHER_UID = "uid_other"
OWNER_TOKEN = f"fake:{OWNER_UID}:+919876543210"
OTHER_TOKEN = f"fake:{OTHER_UID}:+919811122233"
NOTIF_ID = "11111111-1111-1111-1111-111111111111"


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.auth._claims[OWNER_UID] = Role.CUSTOMER
        self.auth._claims[OTHER_UID] = Role.CUSTOMER
        self.notifications = FakeNotificationRepository()
        self.clock = FakeClock(datetime(2026, 6, 1, 10, 0, tzinfo=UTC))
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[notification_repository_dep] = lambda: self.notifications
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[manage_notifications_dep] = lambda: ManageNotifications(
            notifications=self.notifications, clock=self.clock
        )
        self.client = TestClient(app)


@pytest.fixture
def env() -> Iterator[_Env]:
    env = _Env()
    yield env


async def _seed(env: _Env) -> InAppNotification:
    item = InAppNotification(
        id=NOTIF_ID,
        user_id=OWNER_UID,
        template_id="mechanicAssigned",
        title="Mechanic assigned",
        body="Imran will reach you for General Service.",
        deep_link="/tracking?id=b1",
        read_at=None,
        created_at=env.clock.now(),
    )
    return await env.notifications.save(item)


@pytest.mark.asyncio
async def test_read_endpoint_only_owner(env: _Env) -> None:
    await _seed(env)
    owner = env.client.post(f"/v1/notifications/{NOTIF_ID}/read", headers=_headers(OWNER_TOKEN))
    assert owner.status_code == 200
    assert owner.json()["readAt"] is not None

    env.clock.advance(timedelta(minutes=1))
    other = env.client.post(f"/v1/notifications/{NOTIF_ID}/read", headers=_headers(OTHER_TOKEN))
    assert other.status_code == 404
    assert other.json()["error"]["code"] == "not_found"


@pytest.mark.asyncio
async def test_owner_lists_and_deletes(env: _Env) -> None:
    await _seed(env)
    listed = env.client.get("/v1/notifications", headers=_headers(OWNER_TOKEN))
    assert listed.status_code == 200
    assert len(listed.json()["items"]) == 1
    assert listed.json()["items"][0]["title"] == "Mechanic assigned"

    stranger = env.client.get("/v1/notifications", headers=_headers(OTHER_TOKEN))
    assert stranger.status_code == 200
    assert stranger.json()["items"] == []

    deleted = env.client.delete(f"/v1/notifications/{NOTIF_ID}", headers=_headers(OWNER_TOKEN))
    assert deleted.status_code == 204
    gone = env.client.delete(f"/v1/notifications/{NOTIF_ID}", headers=_headers(OWNER_TOKEN))
    assert gone.status_code == 404
