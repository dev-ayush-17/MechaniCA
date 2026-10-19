# 18 — Analytics

## Purpose

See whether the MVP goals in chapter 01 are met. Not advertising. Not a second database of PII.

## Port

`AnalyticsService.track(name, properties)`. The first adapter writes structured logs. A vendor SDK, if added, stays inside the adapter. Properties are checked against the allow-list below. Unknown keys are dropped, not sent.

## Forbidden properties

Phone, OTP, email, name, exact address, lat, lng, registration number, payment session id, token, free-text review body, chat body.

Allowed ids: `bookingId`, `vehicleType`, `serviceCode`, `status`, `method`, `role`, `errorCode`. These are enough to debug funnels.

## Events

| Name | When | Properties |
| --- | --- | --- |
| `app_opened` | Cold start | `role`, `env` |
| `auth_otp_requested` | OTP send | `intent` |
| `auth_succeeded` | Session ready | `intent` |
| `auth_failed` | Verify fail | `errorCode` |
| `booking_started` | Wizard opened | `mode` |
| `booking_step_viewed` | Each step | `step` (`vehicle`, `service`, `schedule`, `address`, `pay`, `review`) |
| `booking_submitted` | Create returned | `mode`, `urgency`, `serviceCode`, `method`, `vehicleType` |
| `booking_submit_failed` | Create error | `errorCode` |
| `dispatch_offer_received` | Mechanic sees offer | `attempt` |
| `dispatch_offer_accepted` | Accept | `attempt` |
| `dispatch_offer_rejected` | Reject or timeout | `attempt`, `reason` |
| `tracking_opened` | Map opened | `status` |
| `location_stale_shown` | Stale banner | `ageSeconds` bucketed `lt60`, `60_300`, `gt300` |
| `extra_work_decided` | Approve or reject | `decision` |
| `payment_started` | Pay tapped | `method` |
| `payment_succeeded` | Status paid | `method` |
| `payment_failed` | Status failed | `method`, `errorCode` |
| `invoice_downloaded` | PDF opened | none |
| `review_submitted` | Review saved | `stars` |
| `offline_banner_shown` | Banner first shown in a session | `screen` |
| `sync_queue_flushed` | Queue drained | `count` |

Server logs the same names for `booking_submitted`, payment, and dispatch so client loss does not hide conversion. Dashboards prefer server events for money and client events for wizard drop-off.

## Funnels that matter

1. `booking_started` → `booking_step_viewed` step review → `booking_submitted`.
2. `booking_submitted` → `dispatch_offer_accepted` → `payment_succeeded`.
3. `payment_started` → `payment_succeeded` by method.

Chapter 01 KPIs map to these events plus the database, not to the client alone.

## Privacy

The adapter's log line uses `userId` only in server logs, which are access-controlled. The client adapter sends `anonymousSessionId` (random, rotated on sign-out) and not `userId`, until a vendor contract says otherwise. Server logs already have `userId` from the request. Do not duplicate it into a third-party tool by default.
