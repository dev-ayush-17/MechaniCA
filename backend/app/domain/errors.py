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


class InvalidWebhookSignature(Unauthenticated):
    code = "invalid_webhook_signature"


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


class TotalChanged(Conflict):
    code = "total_changed"


class AlreadyRefunded(Conflict):
    code = "already_refunded"


class IdempotencyKeyRequired(InvalidInput):
    code = "idempotency_key_required"


class InsufficientWallet(DomainError):
    code = "insufficient_wallet"


class CouponRejected(DomainError):
    code = "coupon_rejected"


class Unavailable(DomainError):
    code = "unavailable"
