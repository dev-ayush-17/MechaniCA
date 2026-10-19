from app.core.logging import redact


def test_logger_drops_sensitive_fields() -> None:
    cleaned = redact({"token": "abc", "Authorization": "Bearer x", "otp": "123456", "route": "/x"})
    assert cleaned == {"route": "/x"}
