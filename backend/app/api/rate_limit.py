"""HTTP token-bucket limits from docs/prd/16-security-and-privacy.md.

Chat send is already limited in the use case (20 / 10 min / booking). OTP
request is enforced in the auth adapter (5 / hour / phone). Those are not
doubled here.
"""

from __future__ import annotations

import uuid
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

from app.api.errors import REQUEST_ID_HEADER

_RETRY = "Retry-After"


@dataclass(frozen=True)
class Window:
    max_hits: int
    period: timedelta


BOOKING_CREATE = Window(10, timedelta(hours=1))
PAYMENT_CREATE = Window(10, timedelta(hours=1))
ADMIN_WRITE = Window(60, timedelta(minutes=1))
PUBLIC_TRACKING = Window(60, timedelta(minutes=1))
WEBHOOK = Window(300, timedelta(minutes=1))


def classify(method: str, path: str) -> tuple[str, Window] | None:
    """Return (group, window) for routes chapter 16 names, else None."""
    normalized = path.rstrip("/") or "/"
    if method == "POST" and normalized == "/v1/bookings":
        return "booking_create", BOOKING_CREATE
    if method == "POST" and normalized == "/v1/payments":
        return "payment_create", PAYMENT_CREATE
    if method == "POST" and normalized == "/v1/payments/cashfree/webhook":
        return "webhook", WEBHOOK
    if method == "GET" and normalized.startswith("/v1/public/tracking"):
        return "public_tracking", PUBLIC_TRACKING
    if method in {"POST", "PUT", "PATCH", "DELETE"} and normalized.startswith("/v1/admin"):
        return "admin_write", ADMIN_WRITE
    return None


class RateLimiter:
    """Sliding window per (group, identity). One instance per process/app."""

    def __init__(self, now: Callable[[], datetime] | None = None) -> None:
        self._now = now or (lambda: datetime.now(UTC))
        self._hits: dict[tuple[str, str], list[datetime]] = {}

    def hit(self, group: str, identity: str, window: Window) -> tuple[bool, int]:
        now = self._now()
        bucket = self._hits.setdefault((group, identity), [])
        cutoff = now - window.period
        bucket[:] = [stamp for stamp in bucket if stamp > cutoff]
        if len(bucket) >= window.max_hits:
            retry = int((bucket[0] + window.period - now).total_seconds()) + 1
            return False, max(retry, 1)
        bucket.append(now)
        return True, 0


def _client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",", 1)[0].strip()
    if request.client is not None:
        return request.client.host
    return "unknown"


def _identities(request: Request, group: str) -> list[str]:
    ip = f"ip:{_client_ip(request)}"
    if group in {"webhook", "public_tracking"}:
        return [ip]
    auth = request.headers.get("authorization", "")
    if auth.lower().startswith("bearer ") and auth[7:].strip():
        return [ip, f"tok:{auth[7:].strip()}"]
    return [ip]


def _too_many(request: Request, retry_after: int) -> JSONResponse:
    request_id = str(getattr(request.state, "request_id", "") or uuid.uuid4().hex)
    return JSONResponse(
        {
            "error": {
                "code": "rate_limited",
                "message": "Try again in a moment.",
                "fields": {},
                "requestId": request_id,
            }
        },
        status_code=429,
        headers={REQUEST_ID_HEADER: request_id, _RETRY: str(retry_after)},
    )


def install_rate_limits(app: FastAPI) -> None:
    limiter = RateLimiter()
    app.state.rate_limiter = limiter

    @app.middleware("http")
    async def rate_limit_middleware(
        request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        classified = classify(request.method, request.url.path)
        if classified is None:
            return await call_next(request)
        group, window = classified
        retry_after = 1
        for identity in _identities(request, group):
            allowed, retry_after = limiter.hit(group, identity, window)
            if not allowed:
                return _too_many(request, retry_after)
        return await call_next(request)
