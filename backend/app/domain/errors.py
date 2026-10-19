"""Typed domain errors. The API layer maps each to an HTTP status and error code
(docs/prd/12-api-contracts.md). Messages are safe to show to a user."""


class DomainError(Exception):
    code = "internal"

    def __init__(self, message: str, *, fields: dict[str, str] | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.fields = fields or {}


class InvalidInput(DomainError):
    code = "invalid_input"


class Unauthenticated(DomainError):
    code = "unauthenticated"


class PermissionDenied(DomainError):
    code = "permission_denied"


class NotFound(DomainError):
    code = "not_found"


class Conflict(DomainError):
    code = "conflict"


class RoleExists(Conflict):
    code = "role_exists"


class InvalidTransition(Conflict):
    code = "invalid_transition"


class BookingInProgress(Conflict):
    code = "booking_in_progress"


class IdempotencyConflict(Conflict):
    code = "idempotency_conflict"


class IdempotencyKeyRequired(InvalidInput):
    code = "idempotency_key_required"


class Unavailable(DomainError):
    code = "unavailable"


class RateLimited(DomainError):
    code = "rate_limited"

    def __init__(self, message: str, *, retry_after_seconds: int = 60) -> None:
        super().__init__(message)
        self.retry_after_seconds = retry_after_seconds
