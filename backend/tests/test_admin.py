from collections.abc import Iterator
from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from app.adapters.fake.address_repository import FakeAddressRepository
from app.adapters.fake.audit_log import FakeAuditLog
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.catalog_repository import FakeCatalogRepository
from app.adapters.fake.clock import FakeClock
from app.adapters.fake.coupon_service import FakeCouponService
from app.adapters.fake.dispute_repository import FakeDisputeRepository
from app.adapters.fake.idempotency_store import FakeIdempotencyStore
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.payment_gateway import FakePaymentGateway
from app.adapters.fake.payment_repository import FakePaymentRepository
from app.adapters.fake.user_repository import FakeUserRepository
from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.adapters.fake.wallet_service import FakeWalletService
from app.adapters.log.analytics import LogAnalyticsService
from app.api.deps import (
    analytics_service_dep,
    audit_log_dep,
    auth_verifier_dep,
    booking_repository_dep,
    clock_dep,
    coupon_service_dep,
    create_booking_dep,
    dispute_repository_dep,
    mechanic_repository_dep,
    payment_gateway_dep,
    payment_repository_dep,
    refund_payment_dep,
    role_claims_dep,
    user_repository_dep,
    vehicle_repository_dep,
    wallet_service_dep,
)
from app.application.create_booking import CreateBooking
from app.application.refund_payment import RefundPayment
from app.domain.analytics import sanitize_properties
from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingMode,
    BookingPolicy,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus
from app.domain.catalog import DEFAULT_PRICING_CONFIG
from app.domain.coupon import CouponRedemption
from app.domain.payment import Payment, PaymentGatewayKind, PaymentReason, PaymentStatus
from app.domain.pricing import PricingService
from app.domain.user import Role, User, UserStatus
from app.domain.vehicle import Vehicle, VehicleType
from app.main import create_app

NOW = datetime(2026, 6, 1, 10, 0, tzinfo=UTC)
CUST_UID = "cust_adm"
CUST_PHONE = "+919876543210"
CUST_TOKEN = f"fake:{CUST_UID}:{CUST_PHONE}"
ADMIN_UID = "admin_adm"
ADMIN_PHONE = "+919800000001"
ADMIN_TOKEN = f"fake:{ADMIN_UID}:{ADMIN_PHONE}"
SUPPORT_UID = "support_adm"
SUPPORT_PHONE = "+919800000002"
SUPPORT_TOKEN = f"fake:{SUPPORT_UID}:{SUPPORT_PHONE}"
VEHICLE_ID = "veh_adm"
KEY = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
ADDR = AddressSnapshot(
    id="addr_home",
    label="Home",
    line1="Boring Road",
    city="Patna",
    pincode="800001",
    lat=25.5941,
    lng=85.1376,
)


def _auth(token: str, key: str | None = None) -> dict[str, str]:
    headers = {"Authorization": f"Bearer {token}"}
    if key:
        headers["Idempotency-Key"] = key
    return headers


def _customer() -> User:
    return User(
        id=CUST_UID,
        role=Role.CUSTOMER,
        name="Riya Sharma",
        phone_e164=CUST_PHONE,
        status=UserStatus.ACTIVE,
        auth_provider="fake",
        auth_subject=CUST_UID,
        created_at=NOW,
        updated_at=NOW,
    )


def _arrived_booking() -> Booking:
    return Booking(
        id="b_disp",
        display_number="MCDISP01",
        customer_id=CUST_UID,
        vehicle_id=VEHICLE_ID,
        service_code="general_service",
        service_name="General Service",
        mode=BookingMode.INSTANT,
        urgency=Urgency.NORMAL,
        status=BookingStatus.ARRIVED,
        payment_method=PaymentMethod.UPI,
        address=ADDR,
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
        mechanic_id="mech_1",
        lines=(),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )


def _paid_payment() -> Payment:
    return Payment(
        id="pay_adm",
        booking_id="b_disp",
        payer_id=CUST_UID,
        method=PaymentMethod.UPI,
        amount_paise=50000,
        status=PaymentStatus.PAID,
        gateway=PaymentGatewayKind.WALLET,
        gateway_order_id=None,
        payment_session_id=None,
        idempotency_key="pay-key",
        reason=PaymentReason.BOOKING,
        refunded_paise=0,
        cash_mechanic_marked_at=None,
        cash_customer_marked_at=None,
        cash_staff_note=None,
        applied_event_ids=(),
        created_at=NOW,
        updated_at=NOW,
        version=1,
    )


def _seed_vehicle(repo: FakeVehicleRepository) -> None:
    repo._by_owner[CUST_UID] = {
        VEHICLE_ID: Vehicle(
            id=VEHICLE_ID,
            owner_id=CUST_UID,
            vehicle_type=VehicleType.TWO_WHEELER,
            brand="TVS",
            model="Apache",
            year=2022,
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


class _Env:
    def __init__(self) -> None:
        self.auth = FakeAuth("test")
        self.users = FakeUserRepository()
        self.bookings = FakeBookingRepository()
        self.payments = FakePaymentRepository()
        self.wallet = FakeWalletService()
        self.coupons = FakeCouponService(now=NOW)
        self.gateway = FakePaymentGateway()
        self.audit = FakeAuditLog()
        self.disputes = FakeDisputeRepository()
        self.analytics = LogAnalyticsService(clock=FakeClock(NOW))
        self.mechanics = FakeMechanicRepository()
        self.vehicles = FakeVehicleRepository()
        self.catalog = FakeCatalogRepository()
        self.addresses = FakeAddressRepository()
        self.idempotency = FakeIdempotencyStore()
        self.clock = FakeClock(NOW)
        self.auth._claims[ADMIN_UID] = Role.ADMIN
        self.auth._claims[SUPPORT_UID] = Role.SUPPORT
        self.users._users[CUST_UID] = _customer()
        self.bookings.bookings["b_disp"] = _arrived_booking()
        self.payments.payments["pay_adm"] = _paid_payment()
        _seed_vehicle(self.vehicles)
        create = CreateBooking(
            catalog=self.catalog,
            vehicles=self.vehicles,
            bookings=self.bookings,
            addresses=self.addresses,
            idempotency=self.idempotency,
            pricing=PricingService(DEFAULT_PRICING_CONFIG),
            clock=self.clock,
            policy=BookingPolicy(),
            coupons=self.coupons,
            wallet=self.wallet,
            users=self.users,
        )
        app = create_app()
        app.dependency_overrides[auth_verifier_dep] = lambda: self.auth
        app.dependency_overrides[role_claims_dep] = lambda: self.auth
        app.dependency_overrides[user_repository_dep] = lambda: self.users
        app.dependency_overrides[booking_repository_dep] = lambda: self.bookings
        app.dependency_overrides[payment_repository_dep] = lambda: self.payments
        app.dependency_overrides[wallet_service_dep] = lambda: self.wallet
        app.dependency_overrides[coupon_service_dep] = lambda: self.coupons
        app.dependency_overrides[payment_gateway_dep] = lambda: self.gateway
        app.dependency_overrides[audit_log_dep] = lambda: self.audit
        app.dependency_overrides[clock_dep] = lambda: self.clock
        app.dependency_overrides[dispute_repository_dep] = lambda: self.disputes
        app.dependency_overrides[analytics_service_dep] = lambda: self.analytics
        app.dependency_overrides[mechanic_repository_dep] = lambda: self.mechanics
        app.dependency_overrides[vehicle_repository_dep] = lambda: self.vehicles
        app.dependency_overrides[create_booking_dep] = lambda: create
        app.dependency_overrides[refund_payment_dep] = lambda: RefundPayment(
            payments=self.payments,
            gateway=self.gateway,
            wallet=self.wallet,
            clock=self.clock,
            audit=self.audit,
        )
        self.client = TestClient(app)

    def open_dispute(self) -> str:
        response = self.client.post(
            "/v1/bookings/b_disp/disputes",
            json={"reason": "Mechanic left early"},
            headers=_auth(CUST_TOKEN),
        )
        assert response.status_code == 201
        return str(response.json()["id"])


@pytest.fixture
def env() -> Iterator[_Env]:
    yield _Env()


def test_support_cannot_resolve_with_refund(env: _Env) -> None:
    dispute_id = env.open_dispute()
    denied = env.client.post(
        f"/v1/admin/disputes/{dispute_id}/resolve",
        json={"resolution": "refund", "amountPaise": 1000, "note": "please refund"},
        headers=_auth(SUPPORT_TOKEN),
    )
    assert denied.status_code == 403
    assert denied.json()["error"]["code"] == "permission_denied"
    assert any(e.action == "dispute_resolve_denied" for e in env.audit.events)

    allowed = env.client.post(
        f"/v1/admin/disputes/{dispute_id}/resolve",
        json={"resolution": "refund", "amountPaise": 1000, "note": "partial refund"},
        headers=_auth(ADMIN_TOKEN, "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
    )
    assert allowed.status_code == 200
    assert allowed.json()["status"] == "resolved"
    assert any(e.action == "dispute_resolve" for e in env.audit.events)
    assert env.payments.payments["pay_adm"].refunded_paise == 1000


def test_suspend_blocks_booking_create(env: _Env) -> None:
    suspend = env.client.post(
        f"/v1/admin/users/{CUST_UID}/suspension",
        json={"reason": "Abuse of SOS"},
        headers=_auth(ADMIN_TOKEN),
    )
    assert suspend.status_code == 200
    assert env.users._users[CUST_UID].status is UserStatus.SUSPENDED
    assert any(e.action == "user_suspend" for e in env.audit.events)

    created = env.client.post(
        "/v1/bookings",
        json={
            "vehicleId": VEHICLE_ID,
            "serviceCode": "general_service",
            "addressId": "addr_home",
            "mode": "instant",
            "urgency": "normal",
            "paymentMethod": "upi",
        },
        headers=_auth(CUST_TOKEN, KEY),
    )
    assert created.status_code == 403
    assert created.json()["error"]["code"] == "account_suspended"


def test_coupon_with_redemptions_cannot_be_edited(env: _Env) -> None:
    env.coupons.redemptions.append(
        CouponRedemption(
            coupon_code="FLAT50",
            user_id=CUST_UID,
            booking_id="b_other",
            amount_paise=5000,
            created_at=NOW,
        )
    )
    edited = env.client.patch(
        "/v1/admin/coupons/FLAT50",
        json={"title": "Changed title", "amount": 2000},
        headers=_auth(ADMIN_TOKEN),
    )
    assert edited.status_code == 400
    assert edited.json()["error"]["code"] == "invalid_input"

    disabled = env.client.post(
        "/v1/admin/coupons/FLAT50/disable",
        headers=_auth(ADMIN_TOKEN),
    )
    assert disabled.status_code == 200
    assert disabled.json()["active"] is False


def test_analytics_drops_phone_property() -> None:
    cleaned = sanitize_properties(
        {"phone": "+919876543210", "method": "upi", "token": "secret", "bookingId": "b1"}
    )
    assert "phone" not in cleaned
    assert "token" not in cleaned
    assert cleaned["method"] == "upi"
    assert cleaned["bookingId"] == "b1"


def test_dispute_second_open_conflicts(env: _Env) -> None:
    first = env.client.post(
        "/v1/bookings/b_disp/disputes",
        json={"reason": "Late arrival"},
        headers=_auth(CUST_TOKEN),
    )
    assert first.status_code == 201
    second = env.client.post(
        "/v1/bookings/b_disp/disputes",
        json={"reason": "Again"},
        headers=_auth(CUST_TOKEN),
    )
    assert second.status_code == 409
    assert second.json()["error"]["code"] == "conflict"


def test_support_cannot_refund_admin_can_both_audited(env: _Env) -> None:
    denied = env.client.post(
        "/v1/admin/refunds",
        json={"paymentId": "pay_adm", "amountPaise": 1000},
        headers=_auth(SUPPORT_TOKEN, "cccccccc-cccc-cccc-cccc-cccccccccccc"),
    )
    assert denied.status_code == 403
    assert any(e.action == "refund_denied" for e in env.audit.events)

    allowed = env.client.post(
        "/v1/admin/refunds",
        json={"paymentId": "pay_adm", "amountPaise": 1000},
        headers=_auth(ADMIN_TOKEN, "dddddddd-dddd-dddd-dddd-dddddddddddd"),
    )
    assert allowed.status_code == 200
    assert allowed.json()["status"] == "partially_refunded"
    assert any(e.action == "refund" for e in env.audit.events)


def test_support_cannot_read_audit(env: _Env) -> None:
    denied = env.client.get("/v1/admin/audit", headers=_auth(SUPPORT_TOKEN))
    assert denied.status_code == 403
    allowed = env.client.get("/v1/admin/audit", headers=_auth(ADMIN_TOKEN))
    assert allowed.status_code == 200


def test_revenue_reads_payments_not_estimates(env: _Env) -> None:
    response = env.client.get("/v1/admin/revenue?window=today", headers=_auth(SUPPORT_TOKEN))
    assert response.status_code == 200
    body = response.json()
    assert body["gmvPaise"] == 50000
    assert body["jobCount"] == 1
    assert body["gmvPaise"] != env.bookings.bookings["b_disp"].total_paise


async def test_analytics_counts_server_events(env: _Env) -> None:
    env.client.post(
        "/v1/bookings/b_disp/disputes",
        json={"reason": "track me"},
        headers=_auth(CUST_TOKEN),
    )
    await env.analytics.track("booking_submitted", {"mode": "instant", "phone": "+91"})
    response = env.client.get("/v1/admin/analytics?days=7", headers=_auth(SUPPORT_TOKEN))
    assert response.status_code == 200
    assert response.json()["counts"]["booking_submitted"] >= 1
    stored = env.analytics.events[-1]
    assert "phone" not in stored.properties
