from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.notification_sender import RecordingNotificationSender
from app.adapters.fake.offer_repository import FakeOfferRepository
from app.api.deps import (
    auth_verifier_dep,
    booking_repository_dep,
    clock_dep,
    dispatch_service_dep,
    mechanic_repository_dep,
    notification_sender_dep,
    offer_repository_dep,
    role_claims_dep,
)
from app.application.dispatch import SequentialDispatch
from app.application.expire_offer import ExpireOffer
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.user import Role
from app.main import create_app

NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
JOB_LAT = 25.5941
JOB_LNG = 85.1376
MECH = "mech_a"
MECH_TOKEN = f"fake:{MECH}:+919811122233"
OTHER = "mech_b"
OTHER_TOKEN = f"fake:{OTHER}:+919811122244"


def _booking() -> Booking:
    return Booking(
        id="book_1",
        display_number="MCBOOK001",
        customer_id="cust_1",
        vehicle_id="veh_1",
        service_code="general_service",
        service_name="General Service",
        mode=BookingMode.INSTANT,
        urgency=Urgency.NORMAL,
        status=BookingStatus.CONFIRMED,
        payment_method=PaymentMethod.UPI,
        address=AddressSnapshot(
            id="addr_home",
            label="Home",
            line1="Fraser Road",
            city="Patna",
            pincode="800001",
            lat=JOB_LAT,
            lng=JOB_LNG,
        ),
        labor_paise=59900,
        parts_paise=0,
        fee_paise=4900,
        discount_paise=0,
        cgst_paise=5800,
        sgst_paise=5800,
        total_paise=76400,
        cancel_fee_paise=0,
        cancel_reason=None,
        scheduled_start=None,
        mechanic_id=None,
        lines=(),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.auth._claims[MECH] = Role.MECHANIC
        self.auth._claims[OTHER] = Role.MECHANIC
        self.clock = FakeClock(NOW)
        self.bookings = FakeBookingRepository()
        self.offers = FakeOfferRepository()
        self.mechanics = FakeMechanicRepository()
        self.notifications = RecordingNotificationSender()
        self.dispatch = SequentialDispatch(
            bookings=self.bookings,
            offers=self.offers,
            mechanics=self.mechanics,
            notifications=self.notifications,
            clock=self.clock,
        )
        self.mechanics.seed_online(MECH, now=NOW, lat=JOB_LAT, lng=JOB_LNG, radius_km=10.0)
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[offer_repository_dep] = lambda: self.offers
        app.dependency_overrides[mechanic_repository_dep] = lambda: self.mechanics
        app.dependency_overrides[notification_sender_dep] = lambda: self.notifications
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[dispatch_service_dep] = lambda: self.dispatch
        self.client = TestClient(app)

    def headers(self, token: str = MECH_TOKEN) -> dict[str, str]:
        return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


@pytest.mark.asyncio
async def test_http_accept_assigns_mechanic(env: _Env) -> None:
    await env.bookings.save(_booking())
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    response = env.client.post(f"/v1/offers/{offer.id}/accept", headers=env.headers())
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "mechanicAssigned"
    assert body["mechanicId"] == MECH


@pytest.mark.asyncio
async def test_http_second_accept_returns_offer_gone(env: _Env) -> None:
    await env.bookings.save(_booking())
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    first = env.client.post(f"/v1/offers/{offer.id}/accept", headers=env.headers())
    assert first.status_code == 200
    second = env.client.post(f"/v1/offers/{offer.id}/accept", headers=env.headers(OTHER_TOKEN))
    assert second.status_code == 409
    assert second.json()["error"]["code"] == "offer_gone"


@pytest.mark.asyncio
async def test_http_reject_then_open_is_gone(env: _Env) -> None:
    env.mechanics.seed_online(OTHER, now=NOW, lat=JOB_LAT + 0.01, lng=JOB_LNG, radius_km=10.0)
    await env.bookings.save(_booking())
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    rejected = env.client.post(f"/v1/offers/{offer.id}/reject", headers=env.headers())
    assert rejected.status_code == 204
    missing = env.client.get("/v1/offers/open", headers=env.headers())
    assert missing.status_code == 404


@pytest.mark.asyncio
async def test_expire_offer_use_case_is_idempotent(env: _Env) -> None:
    env.mechanics.seed_online(OTHER, now=NOW, lat=JOB_LAT + 0.01, lng=JOB_LNG, radius_km=10.0)
    await env.bookings.save(_booking())
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    timeout = ExpireOffer(dispatch=env.dispatch)
    await timeout.execute(offer.id)
    await timeout.execute(offer.id)
    stored = await env.offers.get(offer.id)
    assert stored is not None
    assert stored.status.value == "expired"
