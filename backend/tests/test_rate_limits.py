from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient

from app.api.rate_limit import (
    BOOKING_CREATE,
    PAYMENT_CREATE,
    PUBLIC_TRACKING,
    RateLimiter,
    classify,
)
from app.main import create_app


def test_classify_chapter_16_routes() -> None:
    assert classify("POST", "/v1/bookings") == ("booking_create", BOOKING_CREATE)
    assert classify("POST", "/v1/bookings/") == ("booking_create", BOOKING_CREATE)
    assert classify("POST", "/v1/bookings/abc/cancel") is None
    assert classify("POST", "/v1/bookings/abc/messages") is None
    assert classify("POST", "/v1/payments") == ("payment_create", PAYMENT_CREATE)
    assert classify("POST", "/v1/payments/cashfree/webhook")[0] == "webhook"
    assert classify("GET", "/v1/public/tracking/tok") == ("public_tracking", PUBLIC_TRACKING)
    assert classify("POST", "/v1/admin/users/u1/suspend")[0] == "admin_write"
    assert classify("GET", "/v1/admin/users") is None


def test_eleventh_hit_is_rate_limited() -> None:
    now = datetime(2026, 6, 1, tzinfo=UTC)
    limiter = RateLimiter(now=lambda: now)
    for _ in range(10):
        allowed, _ = limiter.hit("payment_create", "tok:abc", PAYMENT_CREATE)
        assert allowed
    allowed, retry = limiter.hit("payment_create", "tok:abc", PAYMENT_CREATE)
    assert allowed is False
    assert retry >= 1


def test_window_resets() -> None:
    current = datetime(2026, 6, 1, tzinfo=UTC)
    limiter = RateLimiter(now=lambda: current)
    for _ in range(10):
        assert limiter.hit("booking_create", "ip:1", BOOKING_CREATE)[0]
    current = current + timedelta(hours=1, seconds=1)
    assert limiter.hit("booking_create", "ip:1", BOOKING_CREATE)[0]


def test_eleventh_payment_create_is_rate_limited() -> None:
    client = TestClient(create_app())
    for _ in range(10):
        response = client.post("/v1/payments", json={})
        assert response.status_code != 429
    last = client.post("/v1/payments", json={})
    assert last.status_code == 429
    assert last.json()["error"]["code"] == "rate_limited"
    assert last.headers.get("Retry-After")


def test_public_tracking_sixty_first_is_rate_limited() -> None:
    client = TestClient(create_app())
    for i in range(60):
        response = client.get(f"/v1/public/tracking/tok{i}")
        assert response.status_code != 429
    last = client.get("/v1/public/tracking/overflow")
    assert last.status_code == 429
    assert last.json()["error"]["code"] == "rate_limited"
