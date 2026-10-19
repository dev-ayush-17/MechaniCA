from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.address_repository import FakeAddressRepository
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.catalog_repository import FakeCatalogRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.idempotency_store import FakeIdempotencyStore
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.review_repository import FakeReviewRepository
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.api.deps import (
    address_repository_dep,
    auth_verifier_dep,
    booking_repository_dep,
    catalog_repository_dep,
    clock_dep,
    create_booking_dep,
    hide_review_dep,
    idempotency_store_dep,
    list_reviews_dep,
    mechanic_repository_dep,
    review_repository_dep,
    role_claims_dep,
    submit_review_dep,
    vehicle_repository_dep,
)
from app.application.create_booking import CreateBooking
from app.application.reviews import HideReview, ListReviews, SubmitReview
from app.domain.booking import BookingPolicy
from app.domain.booking_state import BookingStatus
from app.domain.catalog import DEFAULT_PRICING_CONFIG
from app.domain.pricing import PricingService
from app.domain.user import Role
from app.domain.vehicle import Vehicle, VehicleType
from app.main import create_app

UID = "uid_rev"
PHONE = "+919876543210"
TOKEN = f"fake:{UID}:{PHONE}"
UID_B = "uid_rev_b"
TOKEN_B = f"fake:{UID_B}:+919800011122"
MECH_UID = "uid_mech_rev"
STAFF_UID = "uid_staff"
STAFF_TOKEN = f"fake:{STAFF_UID}:+919800000001"
VEHICLE_ID = "veh_rev_1"
KEY = "dddddddd-dddd-dddd-dddd-dddddddddddd"
KEY_B = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"


def _auth(token: str, key: str = KEY) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}", "Idempotency-Key": key}


def _seed_vehicle(repo: FakeVehicleRepository, owner: str, vehicle_id: str) -> None:
    now = datetime(2026, 1, 1, tzinfo=UTC)
    repo._by_owner.setdefault(owner, {})[vehicle_id] = Vehicle(
        id=vehicle_id,
        owner_id=owner,
        vehicle_type=VehicleType.TWO_WHEELER,
        brand="TVS",
        model="Apache",
        year=2022,
        registration_number="BR01AB1234",
        fuel_type="petrol",
        color="Black",
        odometer_km=1000,
        is_primary=True,
        created_at=now,
        updated_at=now,
        version=1,
    )


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.catalog = FakeCatalogRepository()
        self.vehicles = FakeVehicleRepository()
        self.bookings = FakeBookingRepository()
        self.addresses = FakeAddressRepository()
        self.idempotency = FakeIdempotencyStore()
        self.reviews = FakeReviewRepository()
        self.mechanics = FakeMechanicRepository()
        self.clock = FakeClock(datetime(2026, 6, 1, 10, 0, tzinfo=UTC))
        self.policy = BookingPolicy()
        _seed_vehicle(self.vehicles, UID, VEHICLE_ID)
        _seed_vehicle(self.vehicles, UID_B, "veh_rev_2")
        self.mechanics.seed_draft(MECH_UID, self.clock.now())
        self.auth._claims[STAFF_UID] = Role.SUPPORT
        pricing = PricingService(DEFAULT_PRICING_CONFIG)
        create = CreateBooking(
            catalog=self.catalog,
            vehicles=self.vehicles,
            bookings=self.bookings,
            addresses=self.addresses,
            idempotency=self.idempotency,
            pricing=pricing,
            clock=self.clock,
            policy=self.policy,
        )
        submit = SubmitReview(
            bookings=self.bookings,
            reviews=self.reviews,
            mechanics=self.mechanics,
            clock=self.clock,
            blocked_words=("spam", "scam"),
        )
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[catalog_repository_dep] = lambda: self.catalog
        app.dependency_overrides[vehicle_repository_dep] = lambda: self.vehicles
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[address_repository_dep] = lambda: self.addresses
        app.dependency_overrides[idempotency_store_dep] = lambda: self.idempotency
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[mechanic_repository_dep] = lambda: self.mechanics
        app.dependency_overrides[review_repository_dep] = lambda: self.reviews
        app.dependency_overrides[create_booking_dep] = lambda: create
        app.dependency_overrides[submit_review_dep] = lambda: submit
        app.dependency_overrides[list_reviews_dep] = lambda: ListReviews(self.reviews)
        app.dependency_overrides[hide_review_dep] = lambda: HideReview(
            reviews=self.reviews, mechanics=self.mechanics
        )
        self.client = TestClient(app)

    def paid_booking(self, token: str = TOKEN, key: str = KEY, vehicle_id: str = VEHICLE_ID) -> str:
        response = self.client.post(
            "/v1/bookings",
            json={
                "vehicleId": vehicle_id,
                "serviceCode": "general_service",
                "addressId": "addr_home",
                "mode": "instant",
                "paymentMethod": "upi",
            },
            headers=_auth(token, key),
        )
        assert response.status_code == 201, response.text
        booking_id = response.json()["id"]
        stored = self.bookings.bookings[booking_id]
        self.bookings.bookings[booking_id] = stored.with_status(
            BookingStatus.PAID, now=self.clock.now(), mechanic_id=MECH_UID
        )
        return str(booking_id)

    def submit(self, booking_id: str, stars: int, text: str = "", token: str = TOKEN):
        return self.client.post(
            "/v1/reviews",
            json={"bookingId": booking_id, "stars": stars, "text": text},
            headers={"Authorization": f"Bearer {token}"},
        )


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_hidden_review_excluded_from_average(env: _Env) -> None:
    first = env.paid_booking()
    second = env.paid_booking(TOKEN_B, KEY_B, "veh_rev_2")
    five = env.submit(first, 5)
    one = env.submit(second, 1, token=TOKEN_B)
    assert five.status_code == 201
    assert one.status_code == 201
    listed = env.client.get(f"/v1/reviews?mechanicId={MECH_UID}")
    assert listed.status_code == 200
    assert listed.json()["ratingCount"] == 2
    assert listed.json()["ratingAvg"] == 3.0
    hidden = env.client.post(
        f"/v1/reviews/{one.json()['id']}/hide",
        headers={"Authorization": f"Bearer {STAFF_TOKEN}"},
    )
    assert hidden.status_code == 200
    after = env.client.get(f"/v1/reviews?mechanicId={MECH_UID}")
    body = after.json()
    assert [item["id"] for item in body["items"]] == [five.json()["id"]]
    assert body["ratingCount"] == 1
    assert body["ratingAvg"] == 5.0
    mechanic = env.mechanics._mechanics[MECH_UID]
    assert mechanic.rating_avg == 5.0
    assert mechanic.rating_count == 1


def test_one_review_per_booking(env: _Env) -> None:
    booking_id = env.paid_booking()
    first = env.submit(booking_id, 5)
    second = env.submit(booking_id, 4, "Nice work")
    assert first.status_code == 201
    assert second.status_code == 409


def test_phone_number_in_review_is_pending_or_rejected(env: _Env) -> None:
    booking_id = env.paid_booking()
    response = env.submit(booking_id, 5, "Call me on 9876543210")
    assert response.status_code == 201
    assert response.json()["status"] in {"pending", "rejected"}
    listed = env.client.get(f"/v1/reviews?mechanicId={MECH_UID}")
    assert listed.json()["ratingCount"] == 0
    assert listed.json()["items"] == []
