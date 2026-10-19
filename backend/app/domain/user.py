from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class Role(StrEnum):
    CUSTOMER = "customer"
    MECHANIC = "mechanic"
    SUPPORT = "support"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"


class UserStatus(StrEnum):
    ACTIVE = "active"
    SUSPENDED = "suspended"


@dataclass(frozen=True)
class Principal:
    """The verified caller. Built from a token, never from a request body."""

    user_id: str
    role: Role
    phone_e164: str | None
    mechanic_verified: bool = False


@dataclass(frozen=True)
class User:
    """Document at users/{userId}. `auth_provider` and `auth_subject` let a later
    vendor migration detach our id from the vendor uid (docs/prd/11-authentication.md)."""

    id: str
    role: Role
    name: str
    phone_e164: str
    status: UserStatus
    auth_provider: str
    auth_subject: str
    created_at: datetime
    updated_at: datetime
