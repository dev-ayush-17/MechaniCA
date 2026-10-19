"""Composition root: the only place that decides which adapter implements a port."""

from functools import lru_cache
from typing import Annotated

from fastapi import Depends, Header

from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.readiness import FakeReadiness
from app.adapters.fake.user_repository import FakeUserRepository
from app.adapters.system_clock import SystemClock
from app.application.bootstrap_user import BootstrapUser
from app.application.manage_vehicles import ManageVehicles
from app.core.config import Settings, get_settings
from app.domain.errors import Unauthenticated
from app.domain.user import Principal
from app.ports.auth_verifier import AuthVerifier
from app.ports.clock import Clock
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
