import re
from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.address_repository import FakeAddressRepository
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.catalog_repository import FakeCatalogRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.file_storage import FakeFileStorage
from app.adapters.fake.idempotency_store import FakeIdempotencyStore
from app.adapters.fake.parts_proof_repository import FakePartsProofRepository
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.api.deps import (
    add_extra_line_dep,
    address_repository_dep,
    auth_verifier_dep,
    booking_repository_dep,
    catalog_repository_dep,
    clock_dep,
    create_booking_dep,
    create_parts_proof_dep,
    decide_extra_line_dep,
    file_storage_dep,
    get_booking_dep,
    hide_parts_proof_dep,
    idempotency_store_dep,
    list_parts_proofs_dep,
    parts_proof_repository_dep,
    role_claims_dep,
    transition_booking_dep,
    vehicle_repository_dep,
)
from app.application.create_booking import CreateBooking
from app.application.extra_line import AddExtraLine, DecideExtraLine
from app.application.get_booking import GetBooking
from app.application.parts_proofs import CreatePartsProof, HidePartsProof, ListPartsProofs
from app.application.transition_booking import TransitionBooking
from app.domain.booking import BookingPolicy
from app.domain.booking_state import BookingStatus
from app.domain.catalog import DEFAULT_PRICING_CONFIG
from app.domain.parts_proof import ProofKind
from app.domain.pricing import PricingService
from app.domain.user import Role
from app.domain.vehicle import Vehicle, VehicleType
from app.main import create_app

PHONE = "+919876543210"
UID = "uid_book"
TOKEN = f"fake:{UID}:{PHONE}"
VEHICLE_ID = "veh_book_1"
KEY = "cccccccc-cccc-cccc-cccc-cccccccccccc"
MECH_UID = "uid_mech"
MECH_TOKEN = f"fake:{MECH_UID}:+919811122233"


def _headers(token: str = TOKEN, key: str = KEY) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}", "Idempotency-Key": key}


def _seed_vehicle(repo: FakeVehicleRepository) -> None:
    now = datetime(2026, 1, 1, tzinfo=UTC)
    repo._by_owner[UID] = {
        VEHICLE_ID: Vehicle(
            id=VEHICLE_ID,
            owner_id=UID,
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
    }


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.catalog = FakeCatalogRepository()
        self.vehicles = FakeVehicleRepository()
        self.bookings = FakeBookingRepository()
        self.addresses = FakeAddressRepository()
        self.idempotency = FakeIdempotencyStore()
        self.proofs = FakePartsProofRepository()
        self.storage = FakeFileStorage()
        self.clock = FakeClock(datetime(2026, 6, 1, 10, 0, tzinfo=UTC))
        self.policy = BookingPolicy()
        _seed_vehicle(self.vehicles)
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
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[catalog_repository_dep] = lambda: self.catalog
        app.dependency_overrides[vehicle_repository_dep] = lambda: self.vehicles
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[address_repository_dep] = lambda: self.addresses
        app.dependency_overrides[idempotency_store_dep] = lambda: self.idempotency
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[file_storage_dep] = lambda: self.storage
        app.dependency_overrides[parts_proof_repository_dep] = lambda: self.proofs
        app.dependency_overrides[create_booking_dep] = lambda: create
        app.dependency_overrides[get_booking_dep] = lambda: GetBooking(self.bookings)
        app.dependency_overrides[add_extra_line_dep] = lambda: AddExtraLine(
            bookings=self.bookings, clock=self.clock, gst_bps=1800
        )
        app.dependency_overrides[decide_extra_line_dep] = lambda: DecideExtraLine(
            bookings=self.bookings, clock=self.clock
        )
        app.dependency_overrides[transition_booking_dep] = lambda: TransitionBooking(
            bookings=self.bookings, clock=self.clock, proofs=self.proofs
        )
        app.dependency_overrides[create_parts_proof_dep] = lambda: CreatePartsProof(
            bookings=self.bookings,
            proofs=self.proofs,
            storage=self.storage,
            clock=self.clock,
        )
        app.dependency_overrides[list_parts_proofs_dep] = lambda: ListPartsProofs(
            bookings=self.bookings, proofs=self.proofs
        )
        app.dependency_overrides[hide_parts_proof_dep] = lambda: HidePartsProof(
            bookings=self.bookings, proofs=self.proofs
        )
        self.client = TestClient(app)

    def create_booking(self) -> str:
        response = self.client.post(
            "/v1/bookings",
            json={
                "vehicleId": VEHICLE_ID,
                "serviceCode": "general_service",
                "addressId": "addr_home",
                "mode": "instant",
                "urgency": "normal",
                "paymentMethod": "upi",
            },
            headers=_headers(),
        )
        assert response.status_code == 201
        return str(response.json()["id"])

    def in_service_with_part(self, booking_id: str) -> str:
        stored = self.bookings.bookings[booking_id]
        self.bookings.bookings[booking_id] = stored.with_status(
            BookingStatus.IN_SERVICE, now=self.clock.now(), mechanic_id=MECH_UID
        )
        self.auth._claims[MECH_UID] = Role.MECHANIC
        added = self.client.post(
            f"/v1/bookings/{booking_id}/lines",
            json={"name": "Brake pads", "amountPaise": 12000},
            headers={"Authorization": f"Bearer {MECH_TOKEN}"},
        )
        assert added.status_code == 201
        pending = [line for line in added.json()["lines"] if line["status"] == "pending_approval"]
        line_id = pending[0]["id"]
        decided = self.client.post(
            f"/v1/bookings/{booking_id}/lines/{line_id}/decision",
            json={"decision": "approve"},
            headers={"Authorization": f"Bearer {TOKEN}"},
        )
        assert decided.status_code == 200
        return str(line_id)

    def upload(self, booking_id: str, line_id: str, kind: ProofKind) -> dict:
        response = self.client.post(
            f"/v1/bookings/{booking_id}/lines/{line_id}/proofs",
            json={"kind": kind.value},
            headers={"Authorization": f"Bearer {MECH_TOKEN}"},
        )
        assert response.status_code == 201, response.text
        return response.json()

    def complete(self, booking_id: str):
        return self.client.post(
            f"/v1/bookings/{booking_id}/transitions",
            json={"to": "completed"},
            headers={"Authorization": f"Bearer {MECH_TOKEN}"},
        )


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_parts_complete_blocked_without_photos(env: _Env) -> None:
    booking_id = env.create_booking()
    line_id = env.in_service_with_part(booking_id)
    env.upload(booking_id, line_id, ProofKind.BEFORE)
    env.upload(booking_id, line_id, ProofKind.AFTER)
    blocked = env.complete(booking_id)
    assert blocked.status_code == 409
    assert blocked.json()["error"]["code"] == "invalid_transition"
    env.upload(booking_id, line_id, ProofKind.OLD_PART)
    allowed = env.complete(booking_id)
    assert allowed.status_code == 200
    assert allowed.json()["status"] == "completed"


def test_proof_path_is_server_chosen(env: _Env) -> None:
    booking_id = env.create_booking()
    line_id = env.in_service_with_part(booking_id)
    body = env.upload(booking_id, line_id, ProofKind.BEFORE)
    path = body["path"]
    pattern = (
        rf"^partsProof/{re.escape(booking_id)}/{re.escape(line_id)}/before/[0-9a-f-]{{36}}\.jpg$"
    )
    assert re.match(pattern, path)
    assert "path" not in {"kind": "before"}
    assert body["metadata"]["bookingId"] == booking_id
    assert body["metadata"]["lineId"] == line_id
    assert body["metadata"]["kind"] == "before"
    assert body["metadata"]["capturedAt"]
    rejected = env.client.post(
        f"/v1/bookings/{booking_id}/lines/{line_id}/proofs",
        json={"kind": "before", "path": "evil/../x.jpg"},
        headers={"Authorization": f"Bearer {MECH_TOKEN}"},
    )
    assert rejected.status_code in {400, 422}


def test_no_parts_complete_still_allowed(env: _Env) -> None:
    booking_id = env.create_booking()
    stored = env.bookings.bookings[booking_id]
    env.bookings.bookings[booking_id] = stored.with_status(
        BookingStatus.IN_SERVICE, now=env.clock.now(), mechanic_id=MECH_UID
    )
    env.auth._claims[MECH_UID] = Role.MECHANIC
    response = env.complete(booking_id)
    assert response.status_code == 200
    assert response.json()["status"] == "completed"
