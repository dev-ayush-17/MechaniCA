from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.chat_service import FakeChatService
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.file_storage import FakeFileStorage
from app.adapters.fake.telephony import FakeTelephony
from app.api.deps import (
    auth_verifier_dep,
    booking_repository_dep,
    chat_service_dep,
    clock_dep,
    file_storage_dep,
    mask_call_dep,
    role_claims_dep,
    send_message_dep,
    sign_chat_media_dep,
)
from app.application.mask_call import MaskCall
from app.application.send_message import SendMessage
from app.application.sign_chat_media import SignChatMedia
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.telephony import MASKED_DIAL_NUMBER
from app.domain.user import Role
from app.main import create_app

CUSTOMER = "cust_1"
MECHANIC = "mech_1"
TOKEN = f"fake:{CUSTOMER}:+910000000001"
MECH_TOKEN = f"fake:{MECHANIC}:+910000000002"
NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
KEY = "cccccccc-cccc-cccc-cccc-cccccccccccc"


def _booking(
    *,
    status: BookingStatus = BookingStatus.MECHANIC_ASSIGNED,
    updated_at: datetime = NOW,
) -> Booking:
    return Booking(
        id="book_1",
        display_number="MCBOOK001",
        customer_id=CUSTOMER,
        vehicle_id="veh_1",
        service_code="general_service",
        service_name="General Service",
        mode=BookingMode.INSTANT,
        urgency=Urgency.NORMAL,
        status=status,
        payment_method=PaymentMethod.UPI,
        address=AddressSnapshot(
            id="addr_1",
            label="Home",
            line1="Patna",
            city="Patna",
            pincode="800001",
            lat=25.59,
            lng=85.13,
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
        mechanic_id=MECHANIC,
        lines=(),
        created_at=NOW,
        updated_at=updated_at,
        version=1,
    )


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.auth._claims[MECHANIC] = Role.MECHANIC
        self.bookings = FakeBookingRepository()
        self.chat = FakeChatService()
        self.clock = FakeClock(NOW)
        self.storage = FakeFileStorage()
        send = SendMessage(bookings=self.bookings, chat=self.chat, clock=self.clock)
        sign = SignChatMedia(storage=self.storage, bookings=self.bookings)
        mask = MaskCall(
            bookings=self.bookings,
            telephony=FakeTelephony(self.clock),
            enabled=True,
        )
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[chat_service_dep] = lambda: self.chat
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[file_storage_dep] = lambda: self.storage
        app.dependency_overrides[send_message_dep] = lambda: send
        app.dependency_overrides[sign_chat_media_dep] = lambda: sign
        app.dependency_overrides[mask_call_dep] = lambda: mask
        self.client = TestClient(app)
        self.bookings.bookings["book_1"] = _booking()

    def send(self, text: str, key: str = KEY, token: str = TOKEN) -> object:
        return self.client.post(
            "/v1/bookings/book_1/messages",
            json={"text": text},
            headers={"Authorization": f"Bearer {token}", "Idempotency-Key": key},
        )


@pytest.fixture
def env() -> _Env:
    return _Env()


def test_send_and_list_omit_phone(env: _Env) -> None:
    created = env.send("On the way?")
    assert created.status_code == 201
    body = created.json()
    assert body["text"] == "On the way?"
    assert body["state"] == "sent"
    assert "phone" not in body
    listed = env.client.get(
        "/v1/bookings/book_1/messages",
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    assert listed.status_code == 200
    item = listed.json()["items"][0]
    assert item["id"] == body["id"]
    assert "phone" not in item


def test_http_closed_chat_is_rejected(env: _Env) -> None:
    env.bookings.bookings["book_1"] = _booking(
        status=BookingStatus.PAID,
        updated_at=NOW - timedelta(hours=25),
    )
    response = env.send("too late")
    assert response.status_code == 400
    assert "closed" in response.json()["error"]["message"]


def test_http_rate_limit_returns_429(env: _Env) -> None:
    for i in range(20):
        key = f"dddddddd-dddd-dddd-dddd-{i:012d}"
        assert env.send(f"msg {i}", key=key).status_code == 201
    last = env.send("one too many", key="eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")
    assert last.status_code == 429
    assert last.json()["error"]["code"] == "rate_limited"
    assert last.headers.get("Retry-After") == "60"


def test_chat_upload_uses_chat_path(env: _Env) -> None:
    response = env.client.post(
        "/v1/bookings/book_1/messages/uploads",
        json={"contentType": "image/jpeg", "maxBytes": 1024},
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    assert response.status_code == 201
    assert response.json()["path"].startswith("chat/book_1/")
    assert "phone" not in response.json()


def test_masked_call_omits_party_phone(env: _Env) -> None:
    response = env.client.post(
        "/v1/bookings/book_1/masked-call",
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["dialNumber"] == MASKED_DIAL_NUMBER
    assert "phone" not in body
    assert CUSTOMER not in str(body)
    assert MECHANIC not in str(body)
