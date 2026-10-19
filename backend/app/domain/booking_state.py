"""Booking status table. Transitions not listed here are illegal (docs/prd/13-state-machines.md)."""

from enum import StrEnum

from app.domain.errors import InvalidTransition
from app.domain.user import Role


class BookingStatus(StrEnum):
    REQUESTED = "requested"
    CONFIRMED = "confirmed"
    MECHANIC_ASSIGNED = "mechanicAssigned"
    EN_ROUTE = "enRoute"
    ARRIVED = "arrived"
    IN_SERVICE = "inService"
    COMPLETED = "completed"
    PAID = "paid"
    CANCELLED = "cancelled"
    FAILED = "failed"
    DISPUTED = "disputed"


# Customer-visible labels from chapter 13. UI may copy these; the server stays on the enum.
STATUS_LABELS: dict[BookingStatus, str] = {
    BookingStatus.REQUESTED: "Sending your request",
    BookingStatus.CONFIRMED: "Finding a mechanic",
    BookingStatus.MECHANIC_ASSIGNED: "Mechanic assigned",
    BookingStatus.EN_ROUTE: "Mechanic is on the way",
    BookingStatus.ARRIVED: "Mechanic arrived",
    BookingStatus.IN_SERVICE: "Service in progress",
    BookingStatus.COMPLETED: "Waiting for payment",
    BookingStatus.PAID: "Paid",
    BookingStatus.CANCELLED: "Cancelled",
    BookingStatus.FAILED: "No mechanic available",
    BookingStatus.DISPUTED: "In review",
}

ACTIVE_STATUSES: frozenset[BookingStatus] = frozenset(
    {
        BookingStatus.REQUESTED,
        BookingStatus.CONFIRMED,
        BookingStatus.MECHANIC_ASSIGNED,
        BookingStatus.EN_ROUTE,
        BookingStatus.ARRIVED,
        BookingStatus.IN_SERVICE,
    }
)

# Customer/support/admin may cancel only from these. Arrived and later need a dispute.
CANCEL_ALLOWED: frozenset[BookingStatus] = frozenset(
    {
        BookingStatus.REQUESTED,
        BookingStatus.CONFIRMED,
        BookingStatus.MECHANIC_ASSIGNED,
        BookingStatus.EN_ROUTE,
    }
)

# (from, to) -> actors that may take the step. "system" is the API process itself.
_TRANSITIONS: dict[tuple[BookingStatus, BookingStatus], frozenset[str]] = {
    (BookingStatus.REQUESTED, BookingStatus.CONFIRMED): frozenset({"system"}),
    (BookingStatus.REQUESTED, BookingStatus.FAILED): frozenset({"system"}),
    (BookingStatus.REQUESTED, BookingStatus.CANCELLED): frozenset(
        {"customer", "support", "admin"}
    ),
    (BookingStatus.CONFIRMED, BookingStatus.MECHANIC_ASSIGNED): frozenset({"system", "admin"}),
    (BookingStatus.CONFIRMED, BookingStatus.FAILED): frozenset({"system", "admin"}),
    (BookingStatus.CONFIRMED, BookingStatus.CANCELLED): frozenset(
        {"customer", "support", "admin"}
    ),
    (BookingStatus.MECHANIC_ASSIGNED, BookingStatus.EN_ROUTE): frozenset({"mechanic"}),
    (BookingStatus.MECHANIC_ASSIGNED, BookingStatus.CONFIRMED): frozenset({"system", "admin"}),
    (BookingStatus.MECHANIC_ASSIGNED, BookingStatus.CANCELLED): frozenset(
        {"customer", "support", "admin"}
    ),
    (BookingStatus.EN_ROUTE, BookingStatus.ARRIVED): frozenset({"mechanic"}),
    (BookingStatus.EN_ROUTE, BookingStatus.CANCELLED): frozenset(
        {"customer", "support", "admin"}
    ),
    (BookingStatus.ARRIVED, BookingStatus.IN_SERVICE): frozenset({"mechanic"}),
    (BookingStatus.ARRIVED, BookingStatus.DISPUTED): frozenset({"customer", "support", "admin"}),
    (BookingStatus.IN_SERVICE, BookingStatus.COMPLETED): frozenset({"mechanic"}),
    (BookingStatus.IN_SERVICE, BookingStatus.DISPUTED): frozenset({"customer", "support", "admin"}),
    (BookingStatus.COMPLETED, BookingStatus.PAID): frozenset({"system", "admin"}),
    (BookingStatus.COMPLETED, BookingStatus.DISPUTED): frozenset({"customer", "support", "admin"}),
    (BookingStatus.PAID, BookingStatus.DISPUTED): frozenset({"customer", "support", "admin"}),
    (BookingStatus.DISPUTED, BookingStatus.PAID): frozenset({"admin"}),
    (BookingStatus.DISPUTED, BookingStatus.CANCELLED): frozenset({"admin"}),
}

_ROLE_ACTOR = {
    Role.CUSTOMER: "customer",
    Role.MECHANIC: "mechanic",
    Role.SUPPORT: "support",
    Role.ADMIN: "admin",
    Role.SUPER_ADMIN: "admin",
}


def actor_for(role: Role) -> str:
    return _ROLE_ACTOR[role]


def can_transition(current: BookingStatus, target: BookingStatus, actor: str) -> bool:
    allowed = _TRANSITIONS.get((current, target))
    return allowed is not None and actor in allowed


def assert_transition(current: BookingStatus, target: BookingStatus, actor: str) -> None:
    if not can_transition(current, target, actor):
        raise InvalidTransition(
            f"This booking can't move from {current.value} to {target.value}."
        )


def can_cancel(status: BookingStatus) -> bool:
    return status in CANCEL_ALLOWED


def cancel_fee_paise(status: BookingStatus, *, enroute_fee_paise: int) -> int:
    """Fee recorded on cancel. Arrived and later must not reach this."""
    if not can_cancel(status):
        raise InvalidTransition(
            "This visit can't be cancelled. Contact support if something is wrong."
        )
    if status is BookingStatus.EN_ROUTE:
        return enroute_fee_paise
    return 0
