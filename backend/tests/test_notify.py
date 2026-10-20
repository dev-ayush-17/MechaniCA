from datetime import UTC, datetime

from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
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
from app.application.cancel_booking import CancelBooking
from app.application.notify import (
    Notify,
    notify_payment_paid,
    notify_verification_approved,
    notify_verification_rejected,
)
from app.application.register_device import RegisterDevice
from app.application.transition_booking import TransitionBooking
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    BookingPolicy,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.notification_templates import Channel, Recipient
from app.domain.user import Principal, Role
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


def _booking(*, status: BookingStatus, mechanic_id: str | None = None) -> Booking:
    now = NOW
    return Booking(
        id="b-notify",
        display_number="MCNOTIFY",
        customer_id="cust",
        vehicle_id="veh_1",
        service_code="general_service",
        service_name="General Service",
        mode=BookingMode.INSTANT,
        urgency=Urgency.NORMAL,
        status=status,
        payment_method=PaymentMethod.UPI,
        address=AddressSnapshot(
            id="addr_home",
            label="Home",
            line1="Rajendra Nagar",
            city="Patna",
            pincode="800001",
            lat=25.5941,
            lng=85.1376,
        ),
        labor_paise=59900,
        parts_paise=0,
        fee_paise=4900,
        discount_paise=0,
        cgst_paise=0,
        sgst_paise=0,
        total_paise=64800,
        cancel_fee_paise=0,
        cancel_reason=None,
        scheduled_start=None,
        mechanic_id=mechanic_id,
        lines=(),
        created_at=now,
        updated_at=now,
        version=1,
    )


async def test_failed_push_does_not_roll_back_booking() -> None:
    clock = FakeClock(NOW)
    bookings = FakeBookingRepository()
    await bookings.save(_booking(status=BookingStatus.CONFIRMED))
    notifications = FakeNotificationRepository()
    sender = RecordingNotificationSender(notifications, clock)
    sender.fail_push_remaining = 9
    notify = Notify(sender=sender, devices=FakeDeviceTokenRepository(), sms_enabled=False)
    use_case = TransitionBooking(bookings=bookings, clock=clock, notify=notify)
    admin = Principal(user_id="admin", role=Role.ADMIN, phone_e164="+919800000000")
    saved = await use_case.execute(admin, "b-notify", target=BookingStatus.MECHANIC_ASSIGNED)
    stored = await bookings.get("b-notify")
    assert saved.status is BookingStatus.MECHANIC_ASSIGNED
    assert stored is not None
    assert stored.status is BookingStatus.MECHANIC_ASSIGNED
    in_app = [
        item for item in notifications.items.values() if item.template_id == "mechanicAssigned"
    ]
    assert len(in_app) == 1
    assert in_app[0].title == "Mechanic assigned"


async def test_cancel_notifies_the_other_party() -> None:
    clock = FakeClock(NOW)
    bookings = FakeBookingRepository()
    await bookings.save(_booking(status=BookingStatus.MECHANIC_ASSIGNED, mechanic_id="mech"))
    notifications = FakeNotificationRepository()
    sender = RecordingNotificationSender(notifications, clock)
    notify = Notify(sender=sender, devices=FakeDeviceTokenRepository())
    use_case = CancelBooking(bookings=bookings, clock=clock, policy=BookingPolicy(), notify=notify)
    customer = Principal(user_id="cust", role=Role.CUSTOMER, phone_e164="+919876543210")
    saved = await use_case.execute(customer, "b-notify", reason="Changed plans")
    assert saved.status is BookingStatus.CANCELLED
    cancelled = [m for m in sender.sent if m.template_id == "bookingCancelled"]
    assert {m.user_id for m in cancelled} == {"mech"}


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
