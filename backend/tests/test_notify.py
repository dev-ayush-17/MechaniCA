from datetime import UTC, datetime

from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.device_token_repository import FakeDeviceTokenRepository
from app.adapters.fake.notification_repository import FakeNotificationRepository
from app.adapters.fake.notification_sender import RecordingNotificationSender
from app.api.deps import (
    auth_verifier_dep,
    clock_dep,
    device_token_repository_dep,
    register_device_dep,
    role_claims_dep,
)
from app.application.notify import (
    Notify,
    notify_payment_paid,
    notify_verification_approved,
    notify_verification_rejected,
)
from app.application.register_device import RegisterDevice
from app.domain.notification_templates import Channel, Recipient
from app.main import create_app

UID = "uid_notify"
TOKEN = f"fake:{UID}:+919876543210"
NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)


def _notify(*, sms_enabled: bool = False) -> tuple[Notify, RecordingNotificationSender]:
    clock = FakeClock(NOW)
    notifications = FakeNotificationRepository()
    sender = RecordingNotificationSender(notifications, clock)
    devices = FakeDeviceTokenRepository()
    return Notify(sender=sender, devices=devices, sms_enabled=sms_enabled), sender


async def test_sms_not_called_when_flag_off() -> None:
    notify, sender = _notify(sms_enabled=False)
    await notify.emit(
        "mechanicAssigned",
        UID,
        {
            "mechanicName": "Imran",
            "serviceName": "General Service",
            "bookingId": "b1",
        },
        recipient=Recipient.CUSTOMER,
    )
    assert sender.sms_calls == 0
    channels = {message.channel for message in sender.sent}
    assert Channel.SMS not in channels
    assert Channel.PUSH in channels
    assert Channel.IN_APP in channels


async def test_payment_paid_templates_send_for_both_parties() -> None:
    notify, sender = _notify()
    await notify_payment_paid(
        notify,
        customer_id="cust",
        mechanic_id="mech",
        data={
            "totalRupees": "₹599",
            "displayNumber": "MCABC123",
            "bookingId": "b1",
            "shareRupees": "₹400",
        },
    )
    in_app = [m for m in sender.sent if m.channel is Channel.IN_APP]
    titles = {m.title for m in in_app}
    assert "Payment successful" in titles
    assert "Job paid" in titles
    assert all(m.title.strip() for m in in_app)


async def test_verification_templates_send_on_direct_call() -> None:
    notify, sender = _notify()
    await notify_verification_approved(notify, mechanic_id="mech", data={})
    await notify_verification_rejected(
        notify, mechanic_id="mech", data={"reason": "Licence photo is blurry."}
    )
    titles = {m.title for m in sender.sent if m.channel is Channel.IN_APP}
    assert "You're verified" in titles
    assert "Verification needs changes" in titles
    rejected = next(
        m
        for m in sender.sent
        if m.template_id == "verificationRejected" and m.channel is Channel.IN_APP
    )
    assert rejected.body == "Licence photo is blurry."


def test_register_device_is_idempotent_by_token() -> None:
    auth = FakeAuth("test")
    devices = FakeDeviceTokenRepository()
    clock = FakeClock(NOW)
    app = create_app()
    app.dependency_overrides[auth_verifier_dep] = lambda: auth
    app.dependency_overrides[role_claims_dep] = lambda: auth
    app.dependency_overrides[device_token_repository_dep] = lambda: devices
    app.dependency_overrides[clock_dep] = lambda: clock
    app.dependency_overrides[register_device_dep] = lambda: RegisterDevice(
        devices=devices, clock=clock
    )
    client = TestClient(app)
    body = {"token": "fcm-debug-token", "platform": "android"}
    headers = {"Authorization": f"Bearer {TOKEN}"}
    first = client.post("/v1/me/devices", json=body, headers=headers)
    second = client.post("/v1/me/devices", json=body, headers=headers)
    assert first.status_code == 200
    assert second.status_code == 200
    assert len(devices.tokens) == 1
