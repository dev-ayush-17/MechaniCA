# Agent progress

Living log. Update this at the end of every session.

## Current

| Field | Value |
| --- | --- |
| Phase | Implementation |
| Branch | `feat/m06-booking` |
| Milestone in progress | M06 booking core. Code and tests are done. PR opening. |
| Next milestone | M07 dispatch. Needs this M06 PR merged. |
| Demo | Runs from `app/` with `flutter run`. Confirm submits `POST /v1/bookings` (fake adapter in demo). Offline confirm shows "Connect to book." and keeps the draft. Cancel after `arrived` shows support copy. |
| Known broken | Nothing known. `flutter analyze` on touched booking files is clean. |

## Completed

| When | What |
| --- | --- |
| 2026-10-19 | Frontend audit on `main` (`069f045`). Flutter 3.44.6, Dart 3.12.2. `flutter analyze`: 160 issues, 1 error (`MyApp` in `widget_test.dart`) |
| 2026-10-19 | PRD chapters 01–25, ADRs 001–014, agent rules, milestone specs (PR #3) |
| 2026-10-19 | M00 foundation (PR #4), M01 frontend foundations (PR #5), M02 auth (PR #6), rename to MechUpp (PR #7), M03 vehicles (PR #9), M04 mechanics (PR #8), M05 catalog/pricing (PR #10). All merged. |
| 2026-10-19 | M06: product booking statuses, idempotent `POST /v1/bookings`, transitions, cancel fees, SOS payload, extra-line approve/reject. Wizard submit and cancel UI. |

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

M07 dispatch per [MILESTONES.md](MILESTONES.md). Start only after this M06 PR is merged.

## M10 notes

Split: API + tests this PR (`feat/m10-payments`). UI (wallet/offers/pay step, mechanic earnings screen, wizard coupon checks) is a second PR against the same spec. Handwritten backend already exceeded ~1,500 lines.

Done:

- Ports: `PaymentGateway`, `PaymentRepository`, `WalletService`, `CouponService`. Fake gateway signs with `mechupp_test_webhook_secret`. Cashfree adapter refuses sandbox keys when `APP_ENV=prod`.
- Webhook verify on the raw body, replay by event id, amount/order mismatch leaves `pending` and writes `payment_mismatch`.
- Wallet ledger (debits cannot go negative except cancel-fee debt), top-up, coupon validate/redeem once, admin refund once, mechanic earnings list from paid shares.
- Cash: mechanic mark + customer confirm, or staff confirm with a note.
- Reconciler: pending Cashfree rows older than 5 minutes go through the same apply path.
- Recording notifier until M09. No invoice PDFs. No PAN/CVV/UPI PIN fields.
- Named tests pass: `webhook_bad_signature_does_not_pay`, `webhook_replay_is_noop`, `webhook_amount_mismatch_does_not_pay`, `wallet_debit_cannot_go_negative`, `coupon_redeem_once`, `cash_requires_both_marks`, `client_sdk_success_is_not_paid`.

Left for PR 2 (same spec, `--base main`):

- Wire `wallet_screen`, `offers_screen`, booking pay step ("Waiting for confirmation").
- Characterization tests then delete wizard-local coupon checks.
- Mechanic earnings screen copy: "Recorded earnings. Bank payout is not live yet."
- Dart `FakeQuoteApi` still returns "Coupons arrive in M10." for nonempty codes; quotes API already applies `FLAT50`.

Not run locally:

- Firestore rules tests (`firebase/tests/rules.test.js`): no Java. CI installs Java 21.
- Cashfree sandbox (no live keys). Fake gateway is the default.
- Flutter UI of this milestone (deferred to PR 2). `flutter analyze` / `flutter test` still run against generated client + existing screens.

Follow-ups:

- Firestore adapters for payments/wallet/coupons (in-memory fakes are the default, matching other M10 ports).
- M09 NotificationSender swap in `deps.py` when that PR merges.
- Invoice PDF is M11.
