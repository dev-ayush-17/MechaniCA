"""Composition root: the only place that decides which adapter implements a port."""

from functools import lru_cache
from typing import Annotated

from fastapi import Depends, Header

from app.adapters.fake.address_repository import FakeAddressRepository
from app.adapters.fake.audit_log import FakeAuditLog
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.catalog_repository import FakeCatalogRepository
from app.adapters.fake.file_storage import FakeFileStorage
from app.adapters.fake.idempotency_store import FakeIdempotencyStore
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.readiness import FakeReadiness
from app.adapters.fake.user_repository import FakeUserRepository
from app.adapters.system_clock import SystemClock
from app.application.bootstrap_user import BootstrapUser
from app.application.cancel_booking import CancelBooking
from app.application.create_booking import CreateBooking
from app.application.create_mechanic_draft import CreateMechanicDraft
from app.application.create_quote import CreateQuote
from app.application.get_booking import GetBooking
from app.application.manage_vehicles import ManageVehicles
from app.application.mechanic_heartbeat import MechanicHeartbeat
from app.application.set_mechanic_availability import SetMechanicAvailability
from app.application.sign_upload import SignUpload
from app.application.submit_mechanic_application import SubmitMechanicApplication
from app.application.transition_booking import TransitionBooking
from app.application.verify_mechanic import VerifyMechanic
from app.core.config import Settings, get_settings
from app.domain.booking import BookingPolicy
from app.domain.catalog import PricingConfig
from app.domain.errors import PermissionDenied, Unauthenticated
from app.domain.pricing import PricingService
from app.domain.user import Principal, Role
from app.ports.address_repository import AddressRepository
from app.ports.audit_log import AuditLog
from app.ports.auth_verifier import AuthVerifier
from app.ports.booking_repository import BookingRepository
from app.ports.catalog_repository import CatalogRepository
from app.ports.clock import Clock
from app.ports.file_storage import FileStorage
from app.ports.idempotency_store import IdempotencyStore
from app.ports.mechanic_repository import MechanicRepository
from app.ports.readiness import ReadinessCheck
from app.ports.role_claims import RoleClaims
from app.ports.user_repository import UserRepository
from app.ports.vehicle_repository import VehicleRepository


def settings_dep() -> Settings:
    return get_settings()


@lru_cache
def _clock() -> Clock:
    return SystemClock()


def clock_dep() -> Clock:
    return _clock()


@lru_cache
def _readiness() -> ReadinessCheck:
    # Later milestones add Firestore and task-queue adapters, selected by Settings.
    return FakeReadiness()


def readiness_dep() -> ReadinessCheck:
    return _readiness()


class _AuthBinding:
    """One vendor object serves both the verifier and the claims port."""

    def __init__(self, verifier: AuthVerifier, claims: RoleClaims) -> None:
        self.verifier = verifier
        self.claims = claims


@lru_cache
def _auth() -> _AuthBinding:
    settings = get_settings()
    if settings.provider_auth == "firebase":
        # Imported here so the Firebase SDK loads only when this adapter is selected.
        from app.adapters.firebase.auth_verifier import FirebaseAuth

        assert settings.firebase_project_id is not None  # noqa: S101 - Settings guarantees it
        firebase = FirebaseAuth(settings.firebase_project_id)
        return _AuthBinding(firebase, firebase)
    fake = FakeAuth(settings.app_env)
    return _AuthBinding(fake, fake)


def auth_verifier_dep() -> AuthVerifier:
    return _auth().verifier


def role_claims_dep() -> RoleClaims:
    return _auth().claims


@lru_cache
def _users() -> UserRepository:
    # A Firestore adapter replaces this in a later milestone. Until then users live in memory.
    return FakeUserRepository()


def user_repository_dep() -> UserRepository:
    return _users()


async def principal_dep(
    verifier: Annotated[AuthVerifier, Depends(auth_verifier_dep)],
    authorization: Annotated[str | None, Header()] = None,
) -> Principal:
    """Resolve the bearer token to a Principal. 401 when it is missing or invalid."""
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise Unauthenticated("Sign in again.")
    return await verifier.verify(token.strip())


@lru_cache
def _vehicles() -> VehicleRepository:
    settings = get_settings()
    if settings.provider_vehicles == "firestore":
        from app.adapters.firebase.vehicle_repository import FirestoreVehicleRepository

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreVehicleRepository(settings.firebase_project_id)
    from app.adapters.fake.vehicle_repository import FakeVehicleRepository

    return FakeVehicleRepository()


def vehicle_repository_dep() -> VehicleRepository:
    return _vehicles()


@lru_cache
def _catalog() -> CatalogRepository:
    settings = get_settings()
    if settings.provider_catalog == "firestore":
        from app.adapters.firebase.catalog_repository import FirestoreCatalogRepository

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreCatalogRepository(settings.firebase_project_id)
    return FakeCatalogRepository()


def catalog_repository_dep() -> CatalogRepository:
    return _catalog()


def pricing_service_dep(
    settings: Annotated[Settings, Depends(settings_dep)],
) -> PricingService:
    return PricingService(
        PricingConfig(
            convenience_fee_paise=settings.convenience_fee_paise,
            four_wheeler_labor_bps=settings.four_wheeler_labor_bps,
            gst_bps=settings.gst_bps,
        )
    )


def create_quote_dep(
    catalog: Annotated[CatalogRepository, Depends(catalog_repository_dep)],
    vehicles: Annotated[VehicleRepository, Depends(vehicle_repository_dep)],
    pricing: Annotated[PricingService, Depends(pricing_service_dep)],
) -> CreateQuote:
    return CreateQuote(catalog=catalog, vehicles=vehicles, pricing=pricing)


def manage_vehicles_dep(
    vehicles: Annotated[VehicleRepository, Depends(vehicle_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> ManageVehicles:
    return ManageVehicles(vehicles=vehicles, clock=clock)


def bootstrap_user_dep(
    users: Annotated[UserRepository, Depends(user_repository_dep)],
    claims: Annotated[RoleClaims, Depends(role_claims_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> BootstrapUser:
    return BootstrapUser(
        users=users, claims=claims, clock=clock, auth_provider=settings.provider_auth
    )


@lru_cache
def _mechanics() -> FakeMechanicRepository:
    return FakeMechanicRepository()


def mechanic_repository_dep() -> MechanicRepository:
    return _mechanics()


@lru_cache
def _storage() -> FileStorage:
    return FakeFileStorage()


def file_storage_dep() -> FileStorage:
    return _storage()


@lru_cache
def _audit() -> AuditLog:
    return FakeAuditLog()


def audit_log_dep() -> AuditLog:
    return _audit()


async def require_mechanic_dep(
    principal: Annotated[Principal, Depends(principal_dep)],
) -> Principal:
    if principal.role != Role.MECHANIC:
        raise PermissionDenied("Mechanic account required.")
    return principal


async def admin_principal_dep(
    principal: Annotated[Principal, Depends(principal_dep)],
) -> Principal:
    if principal.role not in (Role.ADMIN, Role.SUPER_ADMIN):
        raise PermissionDenied("Admin access required.")
    return principal


def create_mechanic_draft_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> CreateMechanicDraft:
    return CreateMechanicDraft(mechanics=mechanics, clock=clock)


def submit_mechanic_application_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> SubmitMechanicApplication:
    return SubmitMechanicApplication(mechanics=mechanics, clock=clock)


def set_mechanic_availability_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
) -> SetMechanicAvailability:
    return SetMechanicAvailability(mechanics=mechanics)


def mechanic_heartbeat_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> MechanicHeartbeat:
    return MechanicHeartbeat(mechanics=mechanics, clock=clock)


def sign_upload_dep(
    storage: Annotated[FileStorage, Depends(file_storage_dep)],
) -> SignUpload:
    return SignUpload(storage=storage)


def verify_mechanic_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    claims: Annotated[RoleClaims, Depends(role_claims_dep)],
    audit: Annotated[AuditLog, Depends(audit_log_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> VerifyMechanic:
    return VerifyMechanic(mechanics=mechanics, claims=claims, audit=audit, clock=clock)


def booking_policy_dep(settings: Annotated[Settings, Depends(settings_dep)]) -> BookingPolicy:
    return BookingPolicy(
        auto_confirm=settings.booking_auto_confirm,
        cancel_fee_enroute_paise=settings.cancel_fee_enroute_paise,
        service_area_lat=settings.service_area_lat,
        service_area_lng=settings.service_area_lng,
        service_area_radius_km=settings.service_area_radius_km,
    )


@lru_cache
def _bookings() -> BookingRepository:
    settings = get_settings()
    if settings.provider_bookings == "firestore":
        from app.adapters.firebase.booking_repository import FirestoreBookingRepository

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreBookingRepository(settings.firebase_project_id)
    return FakeBookingRepository()


def booking_repository_dep() -> BookingRepository:
    return _bookings()


@lru_cache
def _idempotency() -> IdempotencyStore:
    settings = get_settings()
    if settings.provider_bookings == "firestore":
        from app.adapters.firebase.idempotency_store import FirestoreIdempotencyStore

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreIdempotencyStore(settings.firebase_project_id)
    return FakeIdempotencyStore()


def idempotency_store_dep() -> IdempotencyStore:
    return _idempotency()


@lru_cache
def _addresses() -> AddressRepository:
    return FakeAddressRepository()


def address_repository_dep() -> AddressRepository:
    return _addresses()


def create_booking_dep(
    catalog: Annotated[CatalogRepository, Depends(catalog_repository_dep)],
    vehicles: Annotated[VehicleRepository, Depends(vehicle_repository_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    addresses: Annotated[AddressRepository, Depends(address_repository_dep)],
    idempotency: Annotated[IdempotencyStore, Depends(idempotency_store_dep)],
    pricing: Annotated[PricingService, Depends(pricing_service_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    policy: Annotated[BookingPolicy, Depends(booking_policy_dep)],
) -> CreateBooking:
    return CreateBooking(
        catalog=catalog,
        vehicles=vehicles,
        bookings=bookings,
        addresses=addresses,
        idempotency=idempotency,
        pricing=pricing,
        clock=clock,
        policy=policy,
    )


def cancel_booking_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    policy: Annotated[BookingPolicy, Depends(booking_policy_dep)],
) -> CancelBooking:
    return CancelBooking(bookings=bookings, clock=clock, policy=policy)


def transition_booking_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> TransitionBooking:
    return TransitionBooking(bookings=bookings, clock=clock)


def get_booking_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
) -> GetBooking:
    return GetBooking(bookings=bookings)
