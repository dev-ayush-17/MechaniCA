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
