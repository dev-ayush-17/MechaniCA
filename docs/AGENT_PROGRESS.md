# Agent progress

Living log. Update this at the end of every session.

## Current

| Field | Value |
| --- | --- |
| Phase | Implementation |
| Branch | `main` (`844f1d1`) |
| Milestone in progress | None. Wave 4 is merged. |
| Next milestone | M08 live tracking and M11 invoices, in parallel. |
| Demo | Runs from `app/` with `flutter run`. Booking, dispatch, notifications, chat, parts/reviews, and payments are on main (fakes in demo). |
| Known broken | Nothing known. |

## Completed

| When | What |
| --- | --- |
| 2026-10-19 | Frontend audit on `main` (`069f045`). Flutter 3.44.6, Dart 3.12.2. `flutter analyze`: 160 issues, 1 error (`MyApp` in `widget_test.dart`) |
| 2026-10-19 | PRD chapters 01–25, ADRs 001–014, agent rules, milestone specs (PR #3) |
| 2026-10-19 | M00 foundation (PR #4), M01 frontend foundations (PR #5), M02 auth (PR #6), rename to MechUpp (PR #7), M03 vehicles (PR #9), M04 mechanics (PR #8), M05 catalog/pricing (PR #10). All merged. |
| 2026-10-19 | M06: product booking statuses, idempotent `POST /v1/bookings`, transitions, cancel fees, SOS payload, extra-line approve/reject. Wizard submit and cancel UI. |
| 2026-10-20 | Wave 4 merged: M07 dispatch (#15), M09 notifications (#14), M12 chat (#13), M13 parts/reviews (#12), M10 payments API (#16) + UI (#17). |

## M06 notes and follow-ups

| What | Where |
| --- | --- |
| State table | `backend/app/domain/booking_state.py` |
| `BookingRepository` fake + Firestore | `backend/app/ports/booking_repository.py`, adapters |
| `POST /v1/bookings` + cancel + transitions + extra lines | `backend/app/api/v1/bookings.py` |
| Wizard submit + offline error | `app/lib/features/booking/booking_flow_screen.dart`, `price_step.dart` |
| Cancel after arrived | `app/lib/features/booking/presentation/cancel_booking_sheet.dart` |
| SOS payload `urgency=sos` | `app/lib/features/booking/domain/sos_payload.dart` |

Decisions:

- Create lands on `confirmed` (`booking_auto_confirm=true`). No dispatch yet; the job stays confirmed until M07.
- Cancel at `enRoute` records ₹99 (9900 paise) on the booking. No card charge.
- Arrived and later cannot cancel. The sheet shows the support/dispute copy and does not call the API.
- SOS forces `mode=instant` and `serviceCode=breakdown`. Offer timing stays normal until M07.
- Addresses: `addr_home` resolves to a Patna snapshot so the wizard can submit without an addresses API.
- Wizard confirm is `mode=instant`. The leftover date step is still local UI; scheduled-window validation is covered by the API.
- `CancelRequest` was renamed `CancelBookingRequest` so the generated Dart client does not clash with Retrofit's `CancelRequest`.
- Quote test that expected `GET /v1/bookings` to 404 now expects an empty list.

Follow-ups, not done here (scope):

- Real mechanic matching and offer timing (M07).
- Extra-work 10-minute timeout (M07).
- Payment capture (M08).
- Coupon redeem on create (M10).
- Addresses API; wizard still sends `addr_home`.
- Bike step still uses `BikeModel`. Vehicle type for quotes should come from the M03 vehicle.

## Not verified locally

- Firestore rules tests (`firebase/tests/rules.test.js`) were **not run**. This machine has no Java. CI installs Java 21.
- `FirestoreBookingRepository` has not run against the emulator.
- The app was not built for Android or iOS here. Widget tests cover offline confirm, arrived cancel, SOS payload, and extra-line reject.

## Open items that do not block the next milestone

- Production Firebase and GCP projects (owner).
- Cashfree and Google Maps keys (owner).
- Owner: enable GitHub branch protection on `main`.

## Next session

M08 tracking and M11 invoices in parallel from this `main`. Specs: [M08-tracking.md](milestones/M08-tracking.md), [M11-invoices.md](milestones/M11-invoices.md). Do not start M14/M15/M16.

## M10 notes

Split: API + tests on `feat/m10-payments` (PR 1). UI on `feat/m10-payments-ui` (PR 2). Both `--base main`, same spec. Handwritten backend exceeded ~1,500 lines.

Done (PR 1 API):

- Ports: `PaymentGateway`, `PaymentRepository`, `WalletService`, `CouponService`. Fake gateway signs with `mechupp_test_webhook_secret`. Cashfree adapter refuses sandbox keys when `APP_ENV=prod`.
- Webhook verify on the raw body, replay by event id, amount/order mismatch leaves `pending` and writes `payment_mismatch`.
- Wallet ledger (debits cannot go negative except cancel-fee debt), top-up, coupon validate/redeem once, admin refund once, mechanic earnings list from paid shares.
- Cash: mechanic mark + customer confirm, or staff confirm with a note.
- Reconciler: pending Cashfree rows older than 5 minutes go through the same apply path.
- Recording notifier until M09. No invoice PDFs. No PAN/CVV/UPI PIN fields.
- Named tests pass: `webhook_bad_signature_does_not_pay`, `webhook_replay_is_noop`, `webhook_amount_mismatch_does_not_pay`, `wallet_debit_cannot_go_negative`, `coupon_redeem_once`, `cash_requires_both_marks`, `client_sdk_success_is_not_paid`.

Done (PR 2 UI):

- Wallet screen reads the ledger. Empty copy: "No transactions yet." Top-up waits for server confirmation.
- Offers screen lists server coupons. Wizard coupon apply goes through `QuoteApi`. Invalid codes show the server message. `FakeQuoteApi` applies `FLAT50`.
- Booking pay step: fake SDK success shows "Waiting for confirmation" and never "Paid" until GET says paid.
- Mechanic earnings screen: "Recorded earnings. Bank payout is not live yet."

Not run locally:

- Firestore rules tests (`firebase/tests/rules.test.js`): no Java. CI installs Java 21.
- Cashfree sandbox (no live keys). Fake gateway is the default.
- Cashfree checkout SDK (no live keys). Fake checkout returns "success" and does not mark paid.

Follow-ups:

- Firestore adapters for payments/wallet/coupons (in-memory fakes are the default, matching other M10 ports).
- M09 NotificationSender swap in `deps.py` when that PR merges.
- Invoice PDF is M11.
- Live Cashfree SDK checkout on device.

## M13 notes

| Field | Value |
| --- | --- |
| Branch | `feat/m13-parts-reviews` |
| Status | Done. PR opening. |
| Requirements | FR-MEC-008, FR-REV-001..004 |

Done:

- Complete is blocked when a part-replacement line exists and fewer than three proofs are stored. Jobs with no part lines still complete.
- Proof paths are server-chosen (`partsProof/{bookingId}/{lineId}/{kind}/{uuid}.jpg`) with booking/line/timestamp metadata.
- Mechanic capture + offline queue (`image_picker` 1.2.3, reason: capture parts photos).
- Customer inspection route shows server proofs (before/after/old part). Old mock stays at `/inspection/mock` behind a debug button.
- Reviews: one per booking, phone numbers rejected, staff hide via API, aggregates recomputed on the server.
- Firestore rules: reviews and proofs are not client-writable; proofs are not deletable by the mechanic; `ratingAvg`/`ratingCount` stay server-only.

Left / follow-ups:

- Firestore adapters for `ReviewRepository` and `PartsProofRepository` (fakes are bound; real adapters next).
- Pixel-level recompression beyond `image_picker` maxWidth/quality 80.
- Review photo upload UI (API already accepts up to 3 paths).
- Wire submit-review from the paid booking details screen (M10 payment status).

Not run locally:

- Firestore rules tests (`firebase/tests/rules.test.js`): this machine has no Java. CI installs Java 21.
- App not built for Android or iOS here.

Next: wait for CI on the M13 PR. Do not start another milestone in this worktree.

## M12 notes

Branch: `feat/m12-chat`. FR-COM-001–004.

**Done**

- Chat lifecycle: send from `mechanicAssigned` until 24 hours after a terminal status. Named test `message_after_24h_is_rejected`.
- Rate limit 20 / 10 min / booking. Named test `twenty_first_message_is_rate_limited`.
- `POST/GET /v1/bookings/{id}/messages`, chat image sign via `FileStorage` (`POST .../messages/uploads`). API is the only writer.
- Firestore rules: parties read `bookings/{id}/messages`; client writes denied.
- Job chat UI (`features/job_chat/`), polling every 4s, empty-thread copy, failed-message retry, in-memory offline text queue (`offline_text_queues`).
- Chat entry on booking details when a mechanic is assigned. Support FAQ chat is unchanged.
- `TelephonyPort` fake + unavailable adapter. `masked_call_enabled` on in dev, off in prod. Call hidden when off. Adapter never returns a user phone.

**Left / follow-ups, not done here**

- Persist the chat outbox in Drift (`chat_send` kind). Session queue only.
- Firestore snapshot listener. Polling is the writer-safe fallback.
- Image picker on the thread. The API already accepts `mediaPath` after a signed upload.
- Real masked-call vendor. `UnavailableTelephony` stands in until a contract exists.

**Not verified locally**

- Firestore rules tests (`firebase/tests/rules.test.js`): no Java on this machine. CI installs Java 21.
- `FirestoreChatService` was not run against the emulator.
- The app was not built for Android or iOS here.

**Next**

PR against `main`. Do not merge from this session. M07/M09/M10/M13 are parallel and out of this branch.

## M07 notes

Branch: `feat/m07-dispatch` from `origin/main` (M06 merged). Isolated worktree `C:/Users/l/AppDev/Aethenox-m07`.

Done:

- Sequential dispatch: one open offer per booking, max three attempts, ranking from chapter 14 / ADR-013.
- Offer accept/reject HTTP. Second accept loses (`offer_gone`). ExpireOffer and extra-line timeout are safe to run twice.
- Fake `JobScheduler` in dev (`MECHUPP_PROVIDER_SCHEDULER=fake`). Cloud Tasks adapter exists and is never bound in fake/dev.
- Sweep expires leftover offers and pending extra lines if a task was not placed.
- Recording `NotificationSender` fake: `send()` is recorded and never throws into the booking path. No FCM.
- Mechanic offer screen (accept/reject) and legal status buttons. Complete allowed when there are no part lines; part-replacement lines still block (M13).
- Extra-work 10-minute timeout auto-rejects the pending line without changing totals.
- Customer booking-details copy: finding / still looking / failed / SOS failed (chapter 14).
- Named tests: `dispatch_second_accept_loses`, `dispatch_third_miss_fails`, `sos_timeout_is_20_seconds`, `mechanic_with_active_job_is_skipped`, `expired_offer_is_idempotent`, `outside_service_area_excluded`. Widget tests for the offer screen and failed copy.

Left / follow-ups (not this PR):

- Real FCM adapter (M09).
- Map tiles and live tracking (M08). Tracking may still use the old animation.
- Parts photos required to complete (M13).
- Production Cloud Tasks project (owner). Do not block on GCP.

Next: M08 tracking after this PR merges. Parallel milestones (M09, M10, M12, M13) stay on their own branches.

Not run locally:

- Firestore rules tests (`firebase/tests/rules.test.js`): no Java on this machine. CI installs Java 21.
- Firebase emulators.
- Cloud Tasks against a GCP project.
- Android / iOS device builds. Widget tests cover offer UI, status buttons, and failed copy.

## M09 notes

M09 notifications is done on `feat/m09-notifications` from `origin/main` (a6f48ed). Isolated worktree `C:/Users/l/AppDev/Aethenox-m09`.

Done:

- Chapter 17 matrix lives in `backend/app/domain/notification_templates.py`. Every event id has a non-empty title.
- In-app docs at `users/{userId}/notifications/{id}`. Owner list/read/delete via API. Clients cannot write notification docs (rules + test).
- `NotificationSender` port, recording fake, FCM adapter (`backend/app/adapters/fcm.py`). `POST /v1/me/devices` is idempotent by token.
- SMS stays behind `MECHUPP_SMS_ENABLED`, default off. `sms_not_called_when_flag_off` passes.
- Existing notifications screen bound to `features/notifications/`. Empty copy "No notifications yet." Denied banner copy on home. Permission screen calls `requestOnce` once.
- Assigned / arrived / cancelled emit after the booking write. `failed_push_does_not_roll_back_booking` passes.
- Payment and verification templates are sender functions unit-tested with a direct call. M10/M04 can hook them later.

Left / follow-ups:

- No debug FCM token on this machine. Recording fake plus the in-app row is the proof. Do not stall on a Firebase project.
- Real FCM send needs `MECHUPP_PROVIDER_NOTIFY=fcm` and a Firebase project (owner).
- SMS vendor is still out of scope. Flag stays off.
- Offer/extra-work/payment events wait for M07/M10 to call the same `Notify.emit` / `notify_payment_paid`.

Next: open the M09 PR. Do not start another milestone in this worktree.

Not run locally:

- Firestore rules tests (`firebase/tests/rules.test.js`) were **not run**. This machine has no Java. CI installs Java 21.
- `FcmNotificationSender` has not sent a real push.
- The app was not built for Android or iOS here. Widget tests cover empty copy, denied banner copy, and a single OS prompt.
