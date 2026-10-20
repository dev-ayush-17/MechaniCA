from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.job_scheduler import FakeJobScheduler
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.notification_sender import RecordingNotificationSender
from app.adapters.fake.offer_repository import FakeOfferRepository
from app.api.deps import (
    booking_repository_dep,
    clock_dep,
    dispatch_service_dep,
    expire_offer_dep,
    job_scheduler_dep,
    mechanic_repository_dep,
    notification_sender_dep,
    offer_repository_dep,
    sweep_expired_offers_dep,
)
from app.application.dispatch import SequentialDispatch
from app.application.expire_offer import ExpireOffer
from app.application.sweep_jobs import SweepExpiredOffers
from app.core.config import get_settings
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.dispatch import OfferStatus
from app.main import create_app

NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
JOB_LAT = 25.5941
JOB_LNG = 85.1376


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
        self.clock = FakeClock(NOW)
        self.bookings = FakeBookingRepository()
        self.offers = FakeOfferRepository()
        self.mechanics = FakeMechanicRepository()
        self.notifications = RecordingNotificationSender()
        self.scheduler = FakeJobScheduler()
        self.dispatch = SequentialDispatch(
            bookings=self.bookings,
            offers=self.offers,
            mechanics=self.mechanics,
            notifications=self.notifications,
            clock=self.clock,
            scheduler=self.scheduler,
        )
        self.mechanics.seed_online("mech_a", now=NOW, lat=JOB_LAT, lng=JOB_LNG, radius_km=10.0)
        self.mechanics.seed_online(
            "mech_b", now=NOW, lat=JOB_LAT + 0.01, lng=JOB_LNG, radius_km=10.0
        )
        app = create_app()
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[offer_repository_dep] = lambda: self.offers
        app.dependency_overrides[mechanic_repository_dep] = lambda: self.mechanics
        app.dependency_overrides[notification_sender_dep] = lambda: self.notifications
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[job_scheduler_dep] = lambda: self.scheduler
        app.dependency_overrides[dispatch_service_dep] = lambda: self.dispatch
        app.dependency_overrides[expire_offer_dep] = lambda: ExpireOffer(self.dispatch)
        app.dependency_overrides[sweep_expired_offers_dep] = lambda: SweepExpiredOffers(
            offers=self.offers,
            bookings=self.bookings,
            mechanics=self.mechanics,
            dispatch=self.dispatch,
            clock=self.clock,
        )
        self.client = TestClient(app)

    def job_headers(self) -> dict[str, str]:
        return {"X-Internal-Job-Token": get_settings().internal_job_token}


@pytest.fixture
def env() -> _Env:
    return _Env()


def test_dev_binds_fake_scheduler_not_cloud_tasks() -> None:
    assert get_settings().provider_scheduler == "fake"


@pytest.mark.asyncio
async def test_offer_enqueues_timeout_on_fake_scheduler(env: _Env) -> None:
    await env.bookings.save(_booking())
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    assert f"offer-timeout-{offer.id}" in env.scheduler.jobs


@pytest.mark.asyncio
async def test_sweep_expires_due_open_offer(env: _Env) -> None:
    await env.bookings.save(_booking())
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    env.clock.advance(timedelta(seconds=46))
    sweep = SweepExpiredOffers(
        offers=env.offers,
        bookings=env.bookings,
        mechanics=env.mechanics,
        dispatch=env.dispatch,
        clock=env.clock,
    )
    count = await sweep.execute()
    assert count >= 1
    stored = await env.offers.get(offer.id)
    assert stored is not None
    assert stored.status is OfferStatus.EXPIRED


@pytest.mark.asyncio
async def test_internal_timeout_is_idempotent(env: _Env) -> None:
    await env.bookings.save(_booking())
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    first = env.client.post(
        "/v1/internal/jobs/dispatch-timeout",
        json={"offerId": offer.id},
        headers=env.job_headers(),
    )
    second = env.client.post(
        "/v1/internal/jobs/dispatch-timeout",
        json={"offerId": offer.id},
        headers=env.job_headers(),
    )
    assert first.status_code == 200
    assert second.status_code == 200
    stored = await env.offers.get(offer.id)
    assert stored is not None
    assert stored.status is OfferStatus.EXPIRED


def test_internal_jobs_reject_missing_token(env: _Env) -> None:
    response = env.client.post("/v1/internal/jobs/dispatch-sweep")
    assert response.status_code == 401
