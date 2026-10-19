# 12 — API contracts

OpenAPI generated from the FastAPI models is the source of truth once M02 exists. This chapter is the contract those models must follow. If they disagree, fix the code to match this chapter and then regenerate.

## Conventions

- Base URL from config. Version prefix `/v1`. A breaking change increments the prefix. Additive fields are not breaking.
- JSON object bodies. UTF-8.
- Times are strings, ISO-8601, UTC, suffix `Z`.
- Money fields end in `Paise` and are integers.
- Ids are strings.
- Pagination: `?limit=20&cursor=<opaque>`. Response `{ "items": [], "nextCursor": null }`. Default limit 20, max 50.
- Auth: `Authorization: Bearer <token>` except the routes named in chapter 10.
- Every response includes header `X-Request-Id`.

## Idempotency

Required on: `POST /v1/bookings`, `POST /v1/payments`, `POST /v1/wallet/topups`, `POST /v1/admin/refunds`, and any other POST that moves money or creates a booking.

Header: `Idempotency-Key: <uuid>`.

| Situation | Result |
| --- | --- |
| First time | Do the work, store request hash and response for 24 hours |
| Same key, same hash | Return the stored response, same status code |
| Same key, different hash | `409` `idempotency_conflict` |
| Missing key on a required route | `400` `idempotency_key_required` |

Safe retries: the client retries network failures with the same key. It generates a new key only for a new user action.

## Error body

```json
{
  "error": {
    "code": "invalid_transition",
    "message": "This booking can't move from arrived to cancelled.",
    "fields": {},
    "requestId": "3f1c..."
  }
}
```

`message` is safe to show to a user. It does not include stack traces, SQL, or other users' data. `fields` is present for `invalid_input`.

### Codes

| HTTP | code | When |
| --- | --- | --- |
| 400 | `invalid_input` | Validation |
| 400 | `idempotency_key_required` | Money or booking POST without a key |
| 401 | `unauthenticated` | Missing, expired, or bad token |
| 401 | `invalid_webhook_signature` | Cashfree signature failed |
| 403 | `permission_denied` | Wrong role or not a party to the booking |
| 403 | `account_suspended` | User suspended |
| 404 | `not_found` | Hidden as not found when the caller must not learn that the id exists |
| 409 | `invalid_transition` | State machine |
| 409 | `booking_in_progress` | Second active instant booking |
| 409 | `offer_gone` | Another mechanic took it |
| 409 | `idempotency_conflict` | Key reuse with a new body |
| 409 | `already_refunded` | Second refund |
| 409 | `role_exists` | Bootstrap the other role |
| 402 | `insufficient_wallet` | Wallet debit |
| 422 | `coupon_rejected` | Coupon failed. `message` says why |
| 429 | `rate_limited` | Try later. `Retry-After` set |
| 503 | `unavailable` | Downstream down |
| 500 | `internal` | Unexpected. Logged with stack. Body stays generic |

## Booking create

`POST /v1/bookings`

```json
{
  "vehicleId": "uuid",
  "serviceCode": "general_service",
  "mode": "instant",
  "urgency": "normal",
  "addressId": "uuid",
  "paymentMethod": "upi",
  "couponCode": "FLAT50",
  "scheduledStart": null
}
```

`201`:

```json
{
  "id": "uuid",
  "status": "confirmed",
  "displayNumber": "MC3F1C9A2B",
  "estimate": {
    "laborPaise": 59900,
    "partsPaise": 0,
    "feePaise": 4900,
    "discountPaise": 5000,
    "cgstPaise": 5382,
    "sgstPaise": 5382,
    "totalPaise": 70664
  },
  "version": 1
}
```

The server prices the booking. Client-sent totals are ignored if present and must not be in the schema. A client that sends `totalPaise` gets `400 invalid_input` so a bug is loud.

## Transition

`POST /v1/bookings/{id}/transitions`

```json
{ "to": "enRoute", "expectedVersion": 3 }
```

`200` returns the booking. `409` if the version or the transition is wrong.

## Quote

`POST /v1/quotes` with the same pricing inputs and no side effects. Response is the estimate object. The booking create calls the same `PricingService`.

## Payment create

`POST /v1/payments`

```json
{ "bookingId": "uuid", "method": "upi" }
```

`201`:

```json
{
  "paymentId": "uuid",
  "status": "pending",
  "amountPaise": 70664,
  "cashfree": {
    "orderId": "order_...",
    "paymentSessionId": "session_..."
  }
}
```

Wallet and cash responses omit `cashfree`. Wallet that succeeds immediately returns `status=paid`.

## Webhook

`POST /v1/payments/cashfree/webhook` with the raw body preserved for the signature. Response `200` `{ "ok": true }` after the event is stored. Duplicates of the same event id return `200` and do not apply twice.

## Public tracking

`GET /v1/public/tracking/{token}` returns `{ "mechanicFirstName", "vehicleLabel", "status", "etaSeconds", "mechanicLat", "mechanicLng", "destLat", "destLng" }`. No phone, no price, no ids of users. `404` if expired.

## Versioning policy

- Adding a field: allowed.
- Removing or renaming a field: new `/v2` or keep the old field for one release.
- The generated Dart client is committed or built in CI and the app does not hand-edit it.
- Error `code` values above are stable. UI branches on `code`, not on HTTP alone and not on `message` text.

## Client behavior

| HTTP | App |
| --- | --- |
| 401 | Refresh once, else sign out |
| 403 `account_suspended` | Blocking screen with the support number from config |
| 409 `booking_in_progress` | Navigate to the active booking |
| 409 `invalid_transition` | Refresh the booking and show the message |
| 429 | Show "Too many attempts. Wait a moment." Honor `Retry-After` |
| 503 | Show "Service is unavailable. Try again." Retry button |
| Timeout 15s | Same as 503 for user actions. Payment status stays pending and the app polls `GET /v1/payments/{id}` every 3 seconds for up to 2 minutes |
