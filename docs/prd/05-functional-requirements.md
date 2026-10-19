# 05 — Functional requirements

Priorities: **Must**, **Should**, **Could**, **Won't** (Phase 2). Acceptance criteria use Given / When / Then. IDs are stable. Milestones in [MILESTONES.md](../MILESTONES.md) list the IDs they implement.

Amounts are INR. Times are Asia/Kolkata unless a timestamp is stored, in which case storage is UTC.

## 1. Authentication

### FR-AUTH-001 — Phone OTP sign-in (Must)

As a customer or mechanic, I sign in with my Indian mobile number so that the account is mine.

- Given a logged-out user, when they enter a number that is not 10 digits starting 6–9, then the Continue button stays disabled and the field shows "Enter a 10-digit mobile number."
- Given a valid number, when they request an OTP, then a 6-digit code is sent and the screen accepts input for 5 minutes. Resend is disabled for 30 seconds, then allowed, at most 5 sends per number per hour.
- Given the code `123456` in the fake adapter, when they submit it, then sign-in succeeds. The real adapter accepts only the provider's code. Wrong code shows "That code is incorrect." After 5 failures the number is locked for 15 minutes.
- Given success, when the app restarts with a valid session, then it opens the home shell and does not show onboarding again.
- Given the user is offline, when they try to request an OTP, then the screen shows "You're offline. Connect to sign in." No code is queued.

Data: Firebase Auth user, then FastAPI `POST /v1/me/bootstrap` creates the profile if missing. Notifications: none.

### FR-AUTH-002 — Roles and claims (Must)

As the platform, I need every request to know whether the caller is a customer, mechanic, support, admin, or super-admin.

- Given a new phone sign-in, when bootstrap runs, then the role is `customer` unless an invite token says `mechanic`.
- Given any client, when it writes a role or `verified` field, then Security Rules reject the write.
- Given a mechanic who is not verified, when they open the mechanic app, then they can edit their application and cannot go online.

### FR-AUTH-003 — Sign out and session (Must)

- Given a signed-in user, when they sign out, then local tokens, the Drift database for that user, and the queued uploads for that user are deleted, and the login screen is shown.
- Given a revoked token, when the next API call returns 401, then the app signs out and shows "Your session expired. Sign in again."

### FR-AUTH-004 — Google sign-in slot (Should)

The login screen may keep a Google button. Until the adapter exists it is hidden behind the `auth_google_enabled` flag, default off. No fake success.

### FR-AUTH-005 — Forgot password screen (Must)

The current forgot-password screen does not match phone OTP. M02 removes it from the router. Password reset is Won't for MVP.

## 2. Booking and service

### FR-BOOK-001 — Instant booking (Must)

As a customer, I book a mechanic to my current or saved address now.

- Given an online verified-capable account with at least one vehicle, when they finish the wizard and tap Confirm once, then one booking is created with `mode=instant` and status `requested`, then `confirmed` if validation passes.
- Given a double tap or a retry with the same `Idempotency-Key`, when the server handles it, then the same booking id is returned and no second job is dispatched.
- Given no network, when they tap Confirm, then the draft stays on the phone and the button shows "Connect to book." The draft is not submitted later in silence.
- Given they already have a booking in `requested`, `confirmed`, `mechanicAssigned`, `enRoute`, `arrived`, or `inService`, when they try to create another instant booking, then the API returns `409 booking_in_progress` and the app offers to open the active booking.

Validation: vehicle belongs to the caller, service is active, address has lat/lng inside the service area, payment method is one of `upi`, `card`, `netbanking`, `cash`, `wallet`. Card and netbanking are both `online` at Cashfree; the app may show them as separate choices.

UI states: loading on submit, field errors inline, banner if offline, empty state if no vehicle.

### FR-BOOK-002 — Scheduled booking (Must)

- Given a window at least 90 minutes ahead and at most 7 days ahead, on a 60 minute grid, when they confirm, then `mode=scheduled` and dispatch starts 60 minutes before the window.
- Given the window is outside that range, when they confirm, then the date step shows "Choose a time between 90 minutes and 7 days from now."
- Cancellation before the mechanic is assigned is free, including the morning of the job, until status is `mechanicAssigned`.

### FR-BOOK-003 — Service catalog (Must)

As a customer, I pick a service from a catalog, not from a hardcoded list.

Seed services, all active, all editable by admin without an app release:

| Code | Name | Base labor (₹) | Typical duration |
| --- | --- | --- | --- |
| `general_service` | General Service | 599 | 60 min |
| `oil_change` | Oil Change | 399 | 45 min |
| `engine_issue` | Engine Issue | 499 | 90 min |
| `brake_repair` | Brake Repair | 349 | 45 min |
| `breakdown` | Breakdown assist | 499 | 60 min |

- Given the catalog is cached and younger than 24 hours, when the device is offline, then the list still renders and is marked "Updated <time>."
- Given admin deactivates a service, when a new booking is priced, then that service is rejected. Existing bookings keep the snapshot of name and price.

### FR-BOOK-004 — Breakdown / SOS (Must)

- Given the customer taps Emergency and picks a reason (`wont_start`, `breakdown`, `accident_safe`, `other`), when they confirm, then `urgency=sos`, `mode=instant`, service `breakdown`, and dispatch uses the SOS timings in [dispatch](14-dispatch.md).
- Given `accident_safe`, when the screen opens, then copy says "If anyone is hurt, call 112 first." The app does not replace emergency services.
- The SOS form asks for vehicle (default primary) and uses the current location. If location permission is denied, they can pick a saved address or drop a pin. They cannot submit without a point.

### FR-BOOK-005 — Lifecycle (Must)

The legal states and who may move them are in [state machines](13-state-machines.md). Clients never write `status`. Every transition is rejected with `409 invalid_transition` unless the actor and the current state allow it.

### FR-BOOK-006 — Cancellation and fees (Must)

- Given status is `requested`, `confirmed`, or `mechanicAssigned`, when the customer cancels, then the fee is ₹0 and the status is `cancelled`.
- Given status is `enRoute`, when the customer cancels, then the fee is the configured amount (default ₹99). Online fees are collected through the payment flow. Cash fees become a wallet debt or a support follow-up if wallet balance is too low. The booking still cancels. The mechanic sees the fee in earnings.
- Given status is `arrived` or later, when the customer tries to cancel, then the app shows "This visit can't be cancelled. Contact support if something is wrong." and offers dispute.
- Given the mechanic rejects an offer, when the timeout has not fired, then the offer ends and the customer is not charged.
- Given the mechanic is already assigned and their app goes offline for 10 minutes before `enRoute`, when the sweeper runs, then the job is reassigned once and the customer sees "We're finding another mechanic."

### FR-BOOK-007 — Idempotent create (Must)

`POST /v1/bookings` requires header `Idempotency-Key` (UUID, 24 hour retention). Same key and same body returns the original response. Same key and a different body returns `409 idempotency_conflict`.

### FR-BOOK-008 — Reassignment (Must)

See [dispatch](14-dispatch.md). Maximum two reassignments after the first offer (three offers). Then status `failed` and a push to the customer.

### FR-BOOK-009 — Extra work approval (Must)

- Given the mechanic adds a line item, when the new total is higher than the approved estimate, then the customer gets a push and an in-app card: part name, price, GST, and Approve / Reject.
- Given 10 minutes with no answer, when the timer fires, then the line is `rejected` and the mechanic can complete the already approved work.
- Given the customer approves, when they do, then the line is `approved` and is included in the final total. They can approve offline only if the action is queued and the UI says "Will send when you are back online." A timeout that fires before the queue flushes counts as rejection.

## 3. Live tracking and communication

### FR-TRK-001 — Live map (Must)

- Given status is `mechanicAssigned`, `enRoute`, or `arrived`, when the customer opens tracking, then a Google Map shows the mechanic point, the job point, and a route.
- Given the fake adapter, when tests run, then a static map placeholder is acceptable. The real adapter is required for the milestone to be done.
- Given status is `inService` or later, when they open tracking, then the map is replaced by the progress view. Location writes have stopped.

### FR-TRK-002 — Distance and ETA (Must)

- Given two fresh points, when the map is visible, then distance and ETA come from `MapsService` and refresh at most every 30 seconds or when the mechanic moves more than 300 metres.
- Given the maps call fails, when the last ETA is under 5 minutes old, then show it with "Updated just now" replaced by the time. If older, show "ETA unavailable."

### FR-TRK-003 — Mechanic reached (Must)

- Given the mechanic is within 150 metres of the job point, or they tap Arrived, when the server accepts `arrived`, then the customer gets the "Mechanic arrived" notification. The geofence may suggest the button. It does not set status by itself. Status is an API call.

### FR-TRK-004 — Share location both ways (Must)

- The mechanic publishes location during `enRoute` and until 2 minutes after `arrived`.
- The customer may publish location during the same window so the mechanic can find them. A toggle "Share my location" defaults on for SOS and off for scheduled jobs. Off means the mechanic sees only the job pin.

### FR-TRK-005 — Tracking link (Must)

- Given an active booking, when the customer taps Share, then the app creates a link token valid for 6 hours. Opening it shows mechanic first name, vehicle, map, and ETA. It does not show phone numbers, prices, or chat.
- Given the booking is `paid`, `cancelled`, or `failed`, when the link is opened, then the page says "This tracking link has ended."

### FR-TRK-006 — Stale location (Must)

- Given the latest point is older than 60 seconds, when the map renders, then the pin is grey and the label is "Last seen X min ago."
- Given the latest point is older than 5 minutes during `enRoute`, when the sweeper runs, then the customer sees a banner "We're having trouble getting the mechanic's location." Dispatch is not restarted automatically.

### FR-TRK-007 — Battery and data (Must)

Duty cycle is in [assumptions](04-assumptions.md). Background updates on Android use a foreground service notification: "MechaniCA is sharing your trip location." iOS uses the background location mode only while a job is `enRoute`. Updates stop in `inService`. The client batches nothing smaller than the duty cycle. Accuracy target is 50 metres. Points that jump more than 2 km in 5 seconds are dropped as GPS drift and not shown.

### FR-COM-001 — In-app chat (Must)

- Given a booking from `mechanicAssigned` until 24 hours after `paid`, when either party sends text, then the other sees it. After that the thread is read-only.
- Message states: `sending`, `sent`, `failed`. Failed messages can be retried. Text is 1–1000 characters.
- Offline: text queues and shows "Waiting to send."

### FR-COM-002 — Masked calling (Must)

- Given an assigned booking, when either party taps Call, then the app opens the dialer with a masking number from `TelephonyPort`, not the other person's real number.
- Given masking is down, when they tap Call, then show "Calling is unavailable. Use chat." Do not fall back to the raw number.
- The provider is open. MVP ships a port, a fake, and one real adapter interface. If no vendor contract exists at M12, the milestone still ships chat and hides Call behind `masked_call_enabled`, default off in production and on in the fake demo. This is the only allowed cut line, and it is recorded in the M12 spec.

### FR-COM-003 — Chat media (Should)

Images up to 5 MB, JPEG or PNG, compressed on device to max edge 1600 px and quality 80 before upload. Video is Won't. Media uses the same lifecycle as text.

### FR-COM-004 — Chat tied to the booking (Must)

There is no general inbox in MVP. The thread id is the booking id. Support chat in the demo stays a separate FAQ until disputes exist. It is not this thread.

## 4. Vehicles

### FR-VEH-001 — Multiple vehicles (Must)

A customer can add up to 10 vehicles. One is primary. Booking defaults to the primary vehicle.

### FR-VEH-002 — Registration number (Must)

Accept common Indian plates: two letters (state), two digits (RTO), one to three letters, one to four digits, uppercased, spaces ignored. Example accepted: `BR01AB1234`. Example rejected: `BR80Y 024` (the current mock value) with "Enter a valid registration number." Uniqueness is per user. Two users may own the same plate only if we later add transfer. MVP rejects a plate already stored for this user.

Also required: brand, model, year (1980 through next calendar year), vehicle type `two_wheeler` or `four_wheeler`. Optional: fuel type, color, odometer (0–2,000,000 km).

### FR-VEH-003 — Details (Must)

The details screen shows the fields above, insurance and PUC expiry only if the user typed them (no document vault), and the last five services.

### FR-VEH-004 — Service history (Must)

History is the list of bookings for that vehicle in `paid`, `completed`, or `cancelled`. It is not a second source of truth.

### FR-VEH-005 — Health indicators (Should)

Show engine, brakes, battery, tyres, and oil as `good`, `fair`, or `poor`, plus a 0–100 score. MVP computes a placeholder from the last service date: `good` if serviced within 90 days, `fair` within 180, `poor` otherwise, same value for each category, with copy "Based on your last service. A full checkup will replace this." Do not pretend the demo's constant 85 is a measurement.

### FR-VEH-006 — Offline vehicles (Must)

The vehicle list and drafts are stored in Drift. Create and edit queue when offline and flush when online. Conflicts: if the server copy changed, show both and ask the user which to keep. Deletes queue too. The UI shows "Saved on this phone" until the server ack.

## 5. Pricing and payments

### FR-PAY-001 — Estimate (Must)

Before confirm, show lines:

| Line | Source |
| --- | --- |
| Labor | Catalog base, maybe varied later by vehicle type (four-wheeler labor × 1.5, config) |
| Parts | Only known parts. Empty is allowed. |
| Convenience fee | Config |
| Discount | Coupon, computed on labor |
| GST | 18% on labor + convenience fee + parts. Show CGST and SGST |
| Total | Sum |

The estimate is stored on the booking as a snapshot. Later catalog edits do not change it.

### FR-PAY-002 — Estimate versus final (Must)

The final bill can add approved parts and labor. It cannot silently raise the labor rate. If the final total exceeds the estimate, the difference is listed as "Extra work you approved." A final total below the estimate is allowed (work not needed) and the copy says "Lower than the estimate."

### FR-PAY-003 — Customer approval (Must)

Covered by FR-BOOK-009. Payment capture uses the approved total only.

### FR-PAY-004 — Online and UPI (Must)

Cashfree flow is in [payments](15-payments.md). The app never sees a card number. UPI, card, and netbanking all start as a Cashfree order created by FastAPI.

### FR-PAY-005 — Cash (Must)

- Given the customer chose cash, when the mechanic marks the job complete, then both see "Collect ₹X in cash."
- The mechanic taps "Cash collected." The customer taps "I paid cash." Status becomes `paid` only after the customer confirms, or after 2 hours an admin/support can confirm with an audit note.
- If the customer taps "I did not pay", the booking becomes `disputed`.

### FR-PAY-006 — Wallet (Must)

Wallet is a ledger. Balance is the sum of entries, never a field the client sets. Top-up creates a Cashfree order. Paying a booking debits the wallet in the same transaction as marking the payment `paid`. Insufficient balance returns `402 insufficient_wallet` and leaves the booking payable by another method.

### FR-PAY-007 — Coupons (Must)

A coupon has code, type `flat` or `percent`, amount, max discount, min labor, start, end, max redemptions, per-user limit, optional first-booking-only. Validate on estimate and again on pay. Show "Code expired" or "Minimum labor is ₹299" or "Already used." The demo codes may be seeded in dev.

### FR-PAY-008 — Webhooks (Must)

No payment becomes `paid` because the phone said so. Only a verified Cashfree webhook, or a support reconciliation action, moves online payments to `paid`.

### FR-PAY-009 — Idempotency and reconciliation (Must)

Payment create uses `Idempotency-Key`. A sweeper every 15 minutes asks Cashfree about `pending` payments older than 5 minutes and updates them.

### FR-PAY-010 — Refunds (Must)

Admin or the dispute flow can refund an online payment, full or partial, once. Cash refunds are recorded as wallet credit. Double refund returns `409 already_refunded`.

## 6. Invoices

### FR-INV-001 — PDF (Must)

When a booking reaches `paid`, FastAPI generates a PDF and stores it. The customer can download it from the booking. The file includes invoice number, date, customer name, vehicle registration, mechanic display name, line items, GSTIN placeholder from config, CGST, SGST, total, payment method, and booking id.

### FR-INV-002 — GST fields (Must)

Invoice number format `MC-YYYYMM-######`. The sequence is server-side. The PDF is immutable. Regenerating after a bug fix writes a new version and keeps the old file. The app shows the latest.

## 7. Mechanic

### FR-MEC-001 — Public profile (Must)

Customers see: display name, photo, rating average, rating count, years of experience, languages, verified badge, service area name. They do not see documents, phone, or exact home address.

### FR-MEC-002 — Onboarding (Must)

Required to submit: display name (2–40 chars), photo, years (0–50), at least one language, a service area (circle, 1–20 km radius around a point), and the documents in FR-MEC-003.

### FR-MEC-003 — Verification (Must)

Documents: driving licence, government id, a selfie. Each file is JPEG/PNG/PDF, max 5 MB. Admin approves or rejects the whole application with a reason. Rejected mechanics can resubmit. `verified` flips only through the admin endpoint.

### FR-MEC-004 — Availability (Must)

A verified mechanic can toggle online. Online expires if no heartbeat arrives for 2 minutes. Offline mechanics are not offered jobs. Toggling offline during `enRoute` does not drop the current job. It stops new offers.

### FR-MEC-005 — Accept and reject (Must)

The offer screen shows vehicle type, service name, distance, estimate total, and a countdown. Accept is idempotent. The second mechanic to accept gets `409 offer_gone`.

### FR-MEC-006 — Status updates (Must)

The mechanic app shows only the next legal action: Start trip, Arrived, Start service, Complete. Each calls the API. Navigation opens Google Maps directions to the job pin.

### FR-MEC-007 — Earnings (Must)

A list of paid jobs with date, total, mechanic share, and payout status `pending` or `recorded`. MVP records the share. It does not send money to a bank account. Payout transfer is Phase 2. The screen says "Recorded earnings. Bank payout is not live yet."

### FR-MEC-008 — Parts photo proof (Must)

When a line item has `partReplacement=true`, the mechanic must upload three photos before completing: `before`, `after`, `old_part`. Each:

- JPEG, long edge ≤ 1600 px, quality 80, file ≤ 1.5 MB after compression
- Timestamp and booking id and line id burned into the metadata stored by the server (not only EXIF, which the client could edit)
- Storage path `partsProof/{bookingId}/{lineId}/{kind}/{uuid}.jpg`
- Client writes the file only through a signed URL. The proof record is created by FastAPI.
- Offline: photos sit in the upload queue with a local thumbnail. Complete is disabled until the three photos are at least queued, and the server refuses Complete until they are stored.
- Customer sees them on the booking immediately after the server ack. Deleting a proof is not allowed. Admin can mark a photo `hidden` for abuse, which keeps the file and hides it from the customer.

## 8. Reviews and notifications

### FR-REV-001 — Rating (Must)

After `paid`, the customer can set 1–5 stars and 0–500 characters of text, once. They can edit until 48 hours after submit. The mechanic cannot rate the customer in MVP.

### FR-REV-002 — Review photos (Should)

Up to 3 images, same compression as chat. Optional.

### FR-REV-003 — Moderation (Must)

A review with no text is published immediately. A review with text is `pending` until a simple server check: reject if it contains a phone number or a blocked word list stored in config. Support can hide a review. Hidden reviews do not count in the average.

### FR-REV-004 — Aggregates (Must)

`ratingAvg` and `ratingCount` on the mechanic are recomputed by FastAPI when a review is published or hidden. Clients cannot write them. Display average to one decimal.

### FR-NOT-001 — Push (Must)

FCM on Android and iOS for the events in [notifications](17-notifications.md). Tapping opens the deep link.

### FR-NOT-002 — In-app (Must)

The same events appear in the notification list, stored per user, unread badge on the bell. Mark read is allowed for the signed-in user (this is not a money field). Delete is allowed.

### FR-NOT-003 — SMS (Could)

If push token is missing and the event is `mechanicAssigned` or `paymentPaid`, send SMS through the notification port. Default flag off until a provider is configured.

### FR-NOT-004 — Matrix (Must)

The matrix in chapter 17 is the requirement. Adding an event means editing that table and a test.

## 9. Profile and dashboard

### FR-USR-001 — Personal details (Must)

Name (2–60), email optional and validated, photo optional, phone read-only (change phone is Phase 2).

### FR-USR-002 — Addresses (Must)

Up to 10. Label, address line, landmark optional, city, 6-digit PIN, lat/lng from geocoding or the map pin. One default.

### FR-USR-003 — Emergency contacts (Must)

Up to 3. Name and Indian mobile. Used as suggested recipients for the tracking link. The app does not SMS them automatically in MVP.

### FR-USR-004 — Wallet screen (Must)

Balance, last 50 ledger lines, add money. Empty state: "No transactions yet."

### FR-USR-005 — Coupons screen (Must)

Active coupons from the server. Copy code. Applying a code happens in the booking wizard, not only here.

### FR-USR-006 — History (Must)

Tabs: upcoming, active, past. Pull to refresh. Empty copy: "No services yet."

### FR-USR-007 — Repeat service (Should)

On a past paid booking, "Book again" opens the wizard with vehicle, service, and address filled. Date is empty. Price is recalculated. It does not clone the old total.

### FR-USR-008 — Rewards (Won't for rules, Could for display)

If `loyaltyPoints` exists on old fixtures, show it. Do not add an earn or burn API.

### FR-USR-009 — Dashboard (Must)

Home shows: offline banner if needed, active booking card or "Book a service", next scheduled job, primary vehicle and its health label, last three services. It does not show a fake wallet total that disagrees with the ledger.

## 10. Admin

### FR-ADM-001 — Users (Must)

Search by phone or name. Suspend a user with a reason. Suspended users get 403 `account_suspended` on write endpoints.

### FR-ADM-002 — Verification queue (Must)

List `pending` applications, open documents, approve or reject with a reason. Both write an audit event.

### FR-ADM-003 — Orders (Must)

Filter bookings by status, city, date. Open the timeline.

### FR-ADM-004 — Revenue (Must)

Today, 7 days, 30 days: GMV (sum of paid totals), refunds, cash versus online, job count. Figures come from the payment ledger, not from booking estimates.

### FR-ADM-005 — Coupons (Must)

Create, disable, and list coupons. Cannot edit a code that has redemptions. Disable stops new redemptions.

### FR-ADM-006 — Disputes (Must)

Queue of `open` disputes. Support adds notes. Admin records a resolution: `refund`, `no_refund`, or `cash_wallet_credit`, with an amount and a note.

### FR-ADM-007 — Analytics (Should)

A simple count of the events in chapter 18 for the last 7 days. A full product-analytics vendor can be a later adapter.

### FR-ADM-008 — RBAC (Must)

Enforced on the server for every admin route. The web app hides buttons the role cannot use, and the API still checks.

### FR-ADM-009 — Audit log (Must)

Append-only: actor id, role, action, target type, target id, before/after summary, timestamp, request id. The client cannot write it. Admin can read it. Retention 1 year.

## Permissions summary

| Action | Customer | Mechanic | Support | Admin |
| --- | --- | --- | --- | --- |
| Create booking | Own | No | No | No |
| Cancel before arrived | Own, rules apply | No | Yes, with note | Yes |
| Accept job | No | Offered mechanic | No | No |
| Advance job status | No | Assigned mechanic | No | Yes, with audit |
| Pay | Own | No | No | No |
| Confirm cash received | Own confirm | Mark collected | Confirm after 2 hours | Yes |
| Upload parts photos | No | Assigned | No | No |
| Hide review or photo | No | No | Yes | Yes |
| Verify mechanic | No | No | No | Yes |
| Refund | No | No | Request | Execute |
| Grant roles | No | No | No | Super-admin only |

## Edge cases checklist

These must have a test named in the milestone that owns them.

| Case | Expected |
| --- | --- |
| Double tap Confirm | One booking |
| Webhook arrives before the app polls | One `paid` transition |
| Webhook signature invalid | 401, no state change |
| Payment succeeds, webhook delayed | Sweeper reconciles within 15 minutes. UI stays "Waiting for confirmation" |
| Mechanic closes the app mid-trip | Last location goes stale. Job stays assigned |
| GPS jumps 5 km | Point dropped |
| Customer cancels after arrived | Rejected, dispute offered |
| Customer cancels while en route | Fee charged, mechanic notified |
| Coupon expires between estimate and pay | Removed, total refreshed, explicit error |
| Two mechanics accept together | One wins, the other gets `offer_gone` |
| Offline photo upload | Queued, complete blocked on the server until stored |
| User kills the app on the OTP screen | No half-created profile with a role |
| Clock skew on the phone | Server times decide timeouts. The countdown is a hint |
