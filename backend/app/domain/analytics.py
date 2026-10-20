"""Chapter 18 allow-list. Unknown and forbidden keys are dropped, not sent."""

ALLOWED_PROPERTIES = frozenset(
    {
        "bookingId",
        "vehicleType",
        "serviceCode",
        "status",
        "method",
        "role",
        "errorCode",
        "mode",
        "urgency",
        "intent",
        "env",
        "step",
        "attempt",
        "reason",
        "ageSeconds",
        "decision",
        "stars",
        "screen",
        "count",
    }
)

_FORBIDDEN_NORMALIZED = frozenset(
    {
        "phone",
        "otp",
        "email",
        "name",
        "address",
        "exactaddress",
        "exact_address",
        "lat",
        "lng",
        "registration",
        "registrationnumber",
        "registration_number",
        "paymentsessionid",
        "payment_session_id",
        "token",
        "reviewbody",
        "review_body",
        "chatbody",
        "chat_body",
        "body",
    }
)


def sanitize_properties(properties: dict[str, object]) -> dict[str, object]:
    cleaned: dict[str, object] = {}
    for key, value in properties.items():
        normalized = key.replace("-", "").lower()
        if normalized in _FORBIDDEN_NORMALIZED:
            continue
        if key not in ALLOWED_PROPERTIES:
            continue
        cleaned[key] = value
    return cleaned
