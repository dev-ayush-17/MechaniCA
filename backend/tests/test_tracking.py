from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.location_tracking import FakeLocationTrackingService
from app.adapters.fake.maps_service import FakeMapsService
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.tracking_link_store import FakeTrackingLinkStore
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.api.deps import (
    auth_verifier_dep,
    booking_repository_dep,
    clock_dep,
    create_tracking_link_dep,
    get_public_tracking_dep,
    location_tracking_dep,
    maps_service_dep,
    mechanic_repository_dep,
    role_claims_dep,
    tracking_link_store_dep,
    transition_booking_dep,
    vehicle_repository_dep,
)
from app.application.create_tracking_link import CreateTrackingLink
from app.application.get_public_tracking import GetPublicTracking
from app.application.transition_booking import TransitionBooking
from app.domain.booking import AddressSnapshot, Booking, BookingMode, PaymentMethod, Urgency
from app.domain.booking_state import BookingStatus
from app.domain.location import LocationPoint, LocationSnapshot
from app.domain.user import Principal, Role
from app.domain.vehicle import Vehicle, VehicleType
from app.main import create_app

CUSTOMER = "cust_1"
MECHANIC = "mech_1"
TOKEN = f"fake:{CUSTOMER}:+910000000001"
NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
PHONE = "+910000000001"


def _booking(*, status: BookingStatus = BookingStatus.EN_ROUTE) -> Booking:
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
            line1="Boring Road",
            city="Patna",
            pincode="800001",
            lat=25.5941,
            lng=85.1376,
        ),
        labor_paise=59900,
        parts_paise=0,
        fee_paise=4900,
        discount_paise=0,
        cgst_paise=5832,
        sgst_paise=5832,
        total_paise=76464,
        cancel_fee_paise=0,
        cancel_reason=None,
        scheduled_start=None,
        mechanic_id=MECHANIC,
        lines=(),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.auth._claims[MECHANIC] = Role.MECHANIC
        self.bookings = FakeBookingRepository()
        self.locations = FakeLocationTrackingService()
        self.maps = FakeMapsService()
        self.links = FakeTrackingLinkStore()
        self.mechanics = FakeMechanicRepository()
        self.vehicles = FakeVehicleRepository()
        self.clock = FakeClock(NOW)
        self.mechanics.seed_online(
            MECHANIC,
            now=NOW,
            lat=25.61,
            lng=85.14,
            radius_km=10,
            display_name="Rakesh Kumar",
        )
        self.vehicles._by_owner[CUSTOMER] = {
            "veh_1": Vehicle(
                id="veh_1",
                owner_id=CUSTOMER,
                vehicle_type=VehicleType.TWO_WHEELER,
                brand="Hero",
                model="Splendor",
                year=2020,
                registration_number="BR01AB1234",
                fuel_type="petrol",
                color="Black",
                odometer_km=1000,
                is_primary=True,
                created_at=NOW,
                updated_at=NOW,
                version=1,
            )
        }
        create = CreateTrackingLink(bookings=self.bookings, links=self.links, clock=self.clock)
        public = GetPublicTracking(
            links=self.links,
            bookings=self.bookings,
            locations=self.locations,
            maps=self.maps,
            mechanics=self.mechanics,
            vehicles=self.vehicles,
            clock=self.clock,
        )
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[location_tracking_dep] = lambda: self.locations
        app.dependency_overrides[maps_service_dep] = lambda: self.maps
        app.dependency_overrides[tracking_link_store_dep] = lambda: self.links
        app.dependency_overrides[mechanic_repository_dep] = lambda: self.mechanics
        app.dependency_overrides[vehicle_repository_dep] = lambda: self.vehicles
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[create_tracking_link_dep] = lambda: create
        app.dependency_overrides[get_public_tracking_dep] = lambda: public
        app.dependency_overrides[transition_booking_dep] = lambda: TransitionBooking(
            bookings=self.bookings, clock=self.clock, locations=self.locations
        )
        self.client = TestClient(app)
        self.bookings.bookings["book_1"] = _booking()

    def create_link(self) -> object:
        return self.client.post(
            "/v1/bookings/book_1/tracking-links",
            headers={"Authorization": f"Bearer {TOKEN}"},
        )


@pytest.fixture
def env() -> _Env:
    return _Env()


def test_token_hides_phone_and_price(env: _Env) -> None:
    created = env.create_link()
    assert created.status_code == 201
    token = created.json()["token"]
    env.locations._points["book_1"] = LocationSnapshot(
        mechanic=LocationPoint(
            lat=25.61, lng=85.14, accuracy_m=20, recorded_at=NOW, speed_mps=4.0
        )
    )
    response = env.client.get(f"/v1/public/tracking/{token}")
    assert response.status_code == 200
    body = response.json()
    assert set(body) == {
        "mechanicFirstName",
        "vehicleLabel",
        "status",
        "etaSeconds",
        "mechanicLat",
        "mechanicLng",
        "destLat",
        "destLng",
    }
    assert body["mechanicFirstName"] == "Rakesh"
    assert body["vehicleLabel"] == "Hero Splendor"
    assert body["status"] == "enRoute"
    assert body["etaSeconds"] == 720
    blob = str(body)
    assert PHONE not in blob
    assert "phone" not in blob.lower()
    assert "total" not in blob.lower()
    assert "76464" not in blob
    assert CUSTOMER not in blob
    assert MECHANIC not in blob
    assert "price" not in blob.lower()


def test_token_dies_when_paid(env: _Env) -> None:
    token = env.create_link().json()["token"]
    env.bookings.bookings["book_1"] = _booking(status=BookingStatus.PAID)
    response = env.client.get(f"/v1/public/tracking/{token}")
    assert response.status_code == 404
    assert response.json()["error"]["message"] == "This tracking link has ended."


def test_token_dies_when_cancelled(env: _Env) -> None:
    token = env.create_link().json()["token"]
    env.bookings.bookings["book_1"] = _booking(status=BookingStatus.CANCELLED)
    response = env.client.get(f"/v1/public/tracking/{token}")
    assert response.status_code == 404
    assert "ended" in response.json()["error"]["message"]


@pytest.mark.asyncio
async def test_gate_opens_on_assigned_and_closes_in_service(env: _Env) -> None:
    env.bookings.bookings["book_1"] = _booking(status=BookingStatus.CONFIRMED)
    admin = Principal(user_id="admin", role=Role.ADMIN, phone_e164=None)
    mechanic = Principal(user_id=MECHANIC, role=Role.MECHANIC, phone_e164=None)
    use_case = TransitionBooking(
        bookings=env.bookings, clock=env.clock, locations=env.locations
    )
    await use_case.execute(admin, "book_1", target=BookingStatus.MECHANIC_ASSIGNED)
    gate = await env.locations.get_gate("book_1")
    assert gate is not None
    assert gate.location_open is True
    await use_case.execute(mechanic, "book_1", target=BookingStatus.EN_ROUTE)
    await use_case.execute(mechanic, "book_1", target=BookingStatus.ARRIVED)
    await use_case.execute(mechanic, "book_1", target=BookingStatus.IN_SERVICE)
    closed = await env.locations.get_gate("book_1")
    assert closed is not None
    assert closed.location_open is False
