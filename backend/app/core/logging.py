import json
import logging
import sys
from datetime import UTC, datetime
from typing import Any

# Keys that must never reach a log line (docs/prd/08-port-catalog.md, Logger).
SENSITIVE_KEYS = frozenset(
    {"otp", "token", "authorization", "card", "secret", "password", "cvv", "idtoken"}
)


def redact(fields: dict[str, Any]) -> dict[str, Any]:
    """Return a copy of fields without sensitive keys."""
    return {k: v for k, v in fields.items() if k.lower() not in SENSITIVE_KEYS}


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "severity": record.levelname,
            "message": record.getMessage(),
            "time": datetime.now(UTC).isoformat(),
        }
        extra = getattr(record, "fields", None)
        if isinstance(extra, dict):
            payload.update(redact(extra))
        return json.dumps(payload, default=str)


def configure_logging(level: str) -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level)


def log_info(message: str, **fields: Any) -> None:
    logging.getLogger("mechupp").info(message, extra={"fields": fields})
