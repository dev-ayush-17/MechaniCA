from datetime import UTC, datetime, timedelta

import pytest

from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.notification_sender import RecordingNotificationSender
from app.adapters.fake.offer_repository import FakeOfferRepository
from app.application.dispatch import SequentialDispatch
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.dispatch import DispatchConfig, OfferStatus, offer_ttl_seconds, score_candidate
from app.domain.errors import OfferGone

JOB_LAT = 25.5941
JOB_LNG = 85.1376
NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)


def _address() -> AddressSnapshot:
    return AddressSnapshot(
        id="addr_home",
        label="Home",
        line1="Fraser Road",
        city="Patna",
        pincode="800001",
        lat=JOB_LAT,
        lng=JOB_LNG,
    )


def _booking(
    booking_id: str = "book_1",
    *,
    urgency: Urgency = Urgency.NORMAL,
    status: BookingStatus = BookingStatus.CONFIRMED,
    mechanic_id: str | None = None,
    customer_id: str = "cust_1",
) -> Booking:
    return Booking(
        id=booking_id,
        display_number="MCBOOK001",
        customer_id=customer_id,
        vehicle_id="veh_1",
        service_code="breakdown" if urgency is Urgency.SOS else "general_service",
        service_name="Breakdown" if urgency is Urgency.SOS else "General Service",
        mode=BookingMode.INSTANT,
        urgency=urgency,
        status=status,
        payment_method=PaymentMethod.UPI,
        address=_address(),
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
        mechanic_id=mechanic_id,
        lines=(),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )


class _Env:
    def __init__(self, *, notify_fail: bool = False) -> None:
        self.clock = FakeClock(NOW)
        self.bookings = FakeBookingRepository()
        self.offers = FakeOfferRepository()
        self.mechanics = FakeMechanicRepository()
        self.notifications = RecordingNotificationSender(fail=notify_fail)
        self.dispatch = SequentialDispatch(
            bookings=self.bookings,
            offers=self.offers,
            mechanics=self.mechanics,
            notifications=self.notifications,
            clock=self.clock,
        )

    def seed_near(
        self,
        mechanic_id: str,
        *,
        lat: float = JOB_LAT,
        lng: float = JOB_LNG,
        radius_km: float = 10.0,
        rating_avg: float = 4.8,
        rating_count: int = 20,
    ) -> None:
        self.mechanics.seed_online(
            mechanic_id,
            now=self.clock.now(),
            lat=lat,
            lng=lng,
            radius_km=radius_km,
            rating_avg=rating_avg,
            rating_count=rating_count,
            display_name=mechanic_id,
        )

    async def confirmed(
        self,
        booking_id: str = "book_1",
        *,
        urgency: Urgency = Urgency.NORMAL,
    ) -> Booking:
        booking = _booking(booking_id, urgency=urgency)
        await self.bookings.save(booking)
        return booking


@pytest.fixture
def env() -> _Env:
    return _Env()


def test_sos_timeout_constant() -> None:
    assert offer_ttl_seconds(Urgency.SOS) == 20
    assert offer_ttl_seconds(Urgency.NORMAL) == 45


def test_closer_sos_mechanic_outranks_higher_rating() -> None:
    close = score_candidate(
        rating_avg=3.0,
        rating_count=20,
        acceptance=0.8,
        distance_km=1.0,
        recent_offers=0,
        urgency=Urgency.SOS,
    )
    farther = score_candidate(
        rating_avg=5.0,
        rating_count=50,
        acceptance=0.8,
        distance_km=2.5,
        recent_offers=0,
        urgency=Urgency.SOS,
    )
    assert close > farther


@pytest.mark.asyncio
async def test_sos_timeout_is_20_seconds(env: _Env) -> None:
    env.seed_near("mech_a")
    await env.confirmed(urgency=Urgency.SOS)
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    assert offer.expires_at - offer.created_at == timedelta(seconds=20)


@pytest.mark.asyncio
async def test_dispatch_second_accept_loses(env: _Env) -> None:
    env.seed_near("mech_a")
    await env.confirmed()
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    won = await env.dispatch.accept(offer.id, "mech_a")
    assert won.status is BookingStatus.MECHANIC_ASSIGNED
    assert won.mechanic_id == "mech_a"
    again = await env.dispatch.accept(offer.id, "mech_a")
    assert again.id == won.id
    with pytest.raises(OfferGone):
        await env.dispatch.accept(offer.id, "mech_b")
    stored = await env.bookings.get("book_1")
    assert stored is not None
    assert stored.mechanic_id == "mech_a"


@pytest.mark.asyncio
async def test_dispatch_third_miss_fails(env: _Env) -> None:
    env.seed_near("mech_a", lat=JOB_LAT)
    env.seed_near("mech_b", lat=JOB_LAT + 0.01)
    env.seed_near("mech_c", lat=JOB_LAT + 0.02)
    await env.confirmed()
    first = await env.dispatch.offer("book_1")
    assert first is not None
    await env.dispatch.expire(first.id)
    second = next(item for item in env.offers.offers.values() if item.status is OfferStatus.OPEN)
    await env.dispatch.expire(second.id)
    third = next(item for item in env.offers.offers.values() if item.status is OfferStatus.OPEN)
    await env.dispatch.expire(third.id)
    booking = await env.bookings.get("book_1")
    assert booking is not None
    assert booking.status is BookingStatus.FAILED
    assert booking.failure_reason == "no_mechanic"
    assert len(env.offers.offers) == 3
    assert all(item.status is OfferStatus.EXPIRED for item in env.offers.offers.values())


@pytest.mark.asyncio
async def test_mechanic_with_active_job_is_skipped(env: _Env) -> None:
    env.seed_near("mech_busy", rating_avg=5.0)
    env.seed_near("mech_free", lat=JOB_LAT + 0.01, rating_avg=4.0)
    busy_job = _booking(
        "busy_job",
        status=BookingStatus.IN_SERVICE,
        mechanic_id="mech_busy",
        customer_id="cust_busy",
    )
    await env.bookings.save(busy_job)
    await env.confirmed()
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    assert offer.mechanic_id == "mech_free"


@pytest.mark.asyncio
async def test_expired_offer_is_idempotent(env: _Env) -> None:
    env.seed_near("mech_a")
    env.seed_near("mech_b", lat=JOB_LAT + 0.01)
    await env.confirmed()
    first = await env.dispatch.offer("book_1")
    assert first is not None
    await env.dispatch.expire(first.id)
    stored = env.offers.offers[first.id]
    assert stored.status is OfferStatus.EXPIRED
    await env.dispatch.expire(first.id)
    assert env.offers.offers[first.id].status is OfferStatus.EXPIRED
    open_offers = [item for item in env.offers.offers.values() if item.status is OfferStatus.OPEN]
    assert len(open_offers) == 1
    assert open_offers[0].attempt == 2


@pytest.mark.asyncio
async def test_outside_service_area_excluded(env: _Env) -> None:
    # Inside the 5 km search ring, but their signed circle is only 1 km.
    env.seed_near("mech_out", lat=JOB_LAT + 0.036, radius_km=1.0, rating_avg=5.0)
    env.seed_near("mech_in", radius_km=10.0, rating_avg=4.0)
    await env.confirmed()
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    assert offer.mechanic_id == "mech_in"


@pytest.mark.asyncio
async def test_higher_score_gets_the_only_open_offer(env: _Env) -> None:
    env.seed_near("mech_close", rating_avg=4.5)
    env.seed_near("mech_far", lat=JOB_LAT + 0.02, rating_avg=4.5)
    await env.confirmed()
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    assert offer.mechanic_id == "mech_close"
    open_ids = [
        item.mechanic_id for item in env.offers.offers.values() if item.status is OfferStatus.OPEN
    ]
    assert open_ids == ["mech_close"]


@pytest.mark.asyncio
async def test_failed_push_does_not_roll_back_booking() -> None:
    env = _Env(notify_fail=True)
    env.seed_near("mech_a")
    await env.confirmed()
    offer = await env.dispatch.offer("book_1")
    assert offer is not None
    booking = await env.dispatch.accept(offer.id, "mech_a")
    assert booking.status is BookingStatus.MECHANIC_ASSIGNED
    assert env.notifications.sent


def test_dispatch_config_extra_work_is_ten_minutes() -> None:
    assert DispatchConfig().extra_work_timeout_seconds == 600
