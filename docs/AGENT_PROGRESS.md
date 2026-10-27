# Agent progress

Living log. Update this at the end of every session.

## Current

| Field | Value |
| --- | --- |
| Phase | Implementation |
| Branch | `feat/firebase-staging` |
| Milestone in progress | Walkthrough launch hardening (poll, session restore, mechanic ticker). [ADR-019](DECISIONS/019-mechanic-session-ticker.md). |
| Next milestone | Blaze: SMS OTP, then Cashfree/Maps. Owner-only launch in [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). |
| Demo | API on `0.0.0.0:8000`. App: `flutter run --flavor customer` or `--flavor mechanic` with `config/cloud.json` (`http://10.212.74.107:8000`). Seed: `backend/scripts/seed_walkthrough.py`. |
| Known broken | `google-services.json` is still absent; fake OTP does not need it. If the phone cannot open the API, allow inbound TCP 8000. Instant booking is 7:00–21:00 IST; scheduled slots are on the hour in IST (not UTC). |

## Walkthrough hardening (2026-10-26)

Customer details poll `GET /v1/bookings/{id}` (adaptive). Confirm no longer waits on the mock booking store. Wizard last step is Review; Pay (demo) stays on `completed`. Fake/Firebase sessions still persist (no MechaniCA JWT). Mechanic heartbeats while online on any screen; flavor overrides `trackingRole=mechanic`.

Vendor flips (no rewire of use cases):

| Concern | App `--dart-define` / `config/cloud.json` | API env |
| --- | --- | --- |
| Maps | `PROVIDER_MAPS=google` + `MAPS_API_KEY` | `MECHUPP_PROVIDER_MAPS=google` + key |
| Payments | `PROVIDER_PAYMENTS=cashfree` then bind Cashfree SDK on `paymentCheckoutProvider` | `MECHUPP_PROVIDER_PAYMENTS=cashfree` + secrets |
| Auth SMS | `PROVIDER_AUTH=firebase` + `google-services.json` | Firebase Admin |

Do not add Redis. Do not mint API JWTs.

## Walkthrough (2026-10-24)

OTP is `123456`. Type the 10 digits; the login field adds `+91`.

| Role | Number | Who |
| --- | --- | --- |
| Customer | `9811110000` | Any new customer |
| Mechanic | `9800000001` | Ravi Kumar, seeded, verified, offline until Go online |
| Spare mechanic | `9800000002` | Amit Singh, leave offline unless you want a second offer |

1. From `backend/`: `.venv\Scripts\python scripts/seed_walkthrough.py` then `.venv\Scripts\python -m uvicorn app.main:app --host 0.0.0.0 --port 8000`.
2. Debug APKs already built with that config: `app/build/app/outputs/flutter-apk/app-customer-debug.apk` and `app-mechanic-debug.apk`. With the phone plugged in: `adb install -r` each file. Or rebuild with `flutter run --flavor customer -t lib/main.dart -d ZD222M6M9F --dart-define-from-file=config/cloud.json` (and `--flavor mechanic -t lib/main_mechanic.dart` for the mechanic app).
3. Customer app: OTP, then Profile → Edit Profile for the name, My Bikes to add a bike, Emergency Contacts if you want them. Book a service. On the address step tap **Use Patna service area**, then **Save this address**. Leave **As soon as possible**. Submit.
4. Mechanic app, number `9800000001`, same OTP. Home / Jobs / Profile tabs. **Go online** (offers wait up to 10 minutes if you book first). Accept on Jobs or the incoming sheet. Start trip → Arrived → Start service → Complete.
5. Customer booking details (polls every 3s): **Pay (demo)**. Receipt shows Paid. Home lists the job.

Create stays “Finding a mechanic” until Accept. Maps, SMS, and Cashfree stay demo. Dispatch searches 5 km, then 8 km, then 12 km from the job, and the seeded mechanics sit on Patna center (`25.5941, 85.1376`). A GPS fix outside that 12 km circle will not match them. Dev wait is 10 minutes; going online re-runs dispatch for waiting jobs. If a job already shows Failed, book again.

## Completed

| When | What |
| --- | --- |
| 2026-10-19 | Frontend audit on `main` (`069f045`). Flutter 3.44.6, Dart 3.12.2. `flutter analyze`: 160 issues, 1 error (`MyApp` in `widget_test.dart`) |
| 2026-10-19 | PRD chapters 01–25, ADRs 001–014, agent rules, milestone specs (PR #3) |
| 2026-10-19 | M00 foundation (PR #4), M01 frontend foundations (PR #5), M02 auth (PR #6), rename to MechUpp (PR #7), M03 vehicles (PR #9), M04 mechanics (PR #8), M05 catalog/pricing (PR #10). All merged. |
| 2026-10-19 | M06: product booking statuses, idempotent `POST /v1/bookings`, transitions, cancel fees, SOS payload, extra-line approve/reject. Wizard submit and cancel UI. |
| 2026-10-20 | Wave 4 merged: M07 dispatch (#15), M09 notifications (#14), M12 chat (#13), M13 parts/reviews (#12), M10 payments API (#16) + UI (#17). |
| 2026-10-20 | Wave 5: M08 tracking API (#19) + UI (#21) merged. M11 invoices (#20) resolving onto that main. |
| 2026-10-20 | Wave 6: M14 dashboard (#24) and M15 admin API (#22) + UI (#23) merged. |
| 2026-10-20 | M16 hardening on `chore/m16-hardening`. |

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

MVP spec is implemented (M00–M16). Owner-only launch steps: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). Do not add features. Do not deploy production.

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

## M08 notes

Split: API + location port + RTDB rules on `feat/m08-tracking` (PR 1). Tracking UI + MapsService cache on `feat/m08-tracking-ui` (PR 2). Both `--base main`, same spec [M08-tracking.md](milestones/M08-tracking.md). Handwritten diff hit the ~1,500 line cap after the location port.

Requirements: FR-TRK-001..007.

Done (PR 1 API):

- Jump filter (>2 km in 5 s dropped) and stale-at-60s as pure functions in Dart and Python. Named tests `stale_after_60_seconds`, `jump_over_2km_dropped`.
- API location gate: `locationOpen` on `bookingGates/{bookingId}` when status is `mechanicAssigned` / `enRoute` / `arrived`. Closed on `inService` and terminal. Clients never write gates.
- `POST /v1/bookings/{id}/tracking-links` (customer, 6 h). `GET /v1/public/tracking/{token}` returns mechanic first name, vehicle, status, ETA, points. No phone, no price, no user ids. 404 copy: "This tracking link has ended." Named tests `token_hides_phone_and_price`, `token_dies_when_paid`.
- RTDB rules for `liveLocations/{bookingId}/{ownRole}` while the gate is open. Named tests `rules_allow_own_location_write`, `rules_deny_other_party_location_write`.
- Flutter `LocationTrackingService` port, in-memory fake, RTDB adapter (publish/subscribe own node only). Bound in `composition/providers.dart`.

Done (PR 2 UI):

- Fake workshop timeline (`pickedUp` / `inWorkshop` / `outForDelivery`) removed. Live tracking shows map states for product statuses. `inService`+ is a progress view.
- Distance and ETA are text even if map tiles fail. Point older than 60 s: grey pin + "Last seen…". enRoute + >5 min: trouble banner (dispatch is not restarted).
- Fake `MapsService` is the default (Patna `RouteSummary`). Google HTTPS adapter exists under `data/adapters/` and is bound only when `PROVIDER_MAPS=google` and `MAPS_API_KEY` is set. No maps key in git.
- Route cache: at most every 30 s, or when the origin moves more than 300 m. Maps fail: last ETA if younger than 5 min, else "ETA unavailable."
- Share tracking creates a token and shares the public URL (`share_plus` already pinned; reason: share tracking link). "Share my location" defaults ON for SOS, OFF for scheduled.
- Mechanic copy: "MechUpp is sharing your trip location." Geofence 150 m may suggest Arrived; it does not set status.
- Emergency tracking route reuses `LiveTrackingScreen`.

Not run locally:

- Firestore/RTDB rules tests (`firebase/tests/rules.test.js`): no Java on this machine. CI installs Java 21.
- Google Maps on a device (no key). Fake map is the demo default.
- Two-emulator live RTDB session.

Follow-ups, not this milestone:

- Device GPS sampler / geolocator loop using the duty-cycle helpers (`dutyInterval` 5 s / 15 s, stop 2 min after arrived). Port `publish` is ready.
- Emergency-contact picking (M14). Hindi (M16). Turn-by-turn in-app (out of scope; Directions opens Google Maps).
- `google_maps_flutter` tiles. Fake placeholder is enough; Directions HTTP is the real Maps adapter.

Packages: `firebase_database` 11.3.8 (RTDB live location, PR 1). No new packages on PR 2 (`share_plus` 11.0.0 already present).

## M11 notes

Branch: `feat/m11-invoices` from `origin/main` (a06c200, M10 merged). Isolated worktree. FR-INV-001, FR-INV-002.

Done:

- `InvoiceService.render/get`, month-scoped numbers `MC-YYYYMM-######`, GST 18% as CGST 9% + SGST 9% in paise. Invoice total equals the paid payment.
- PDF via **reportlab** (pinned `reportlab==5.0.1`) in `backend/app/adapters/pdf.py`. Reason: no OS packages in the Cloud Run image, unlike WeasyPrint.
- After paid (gateway apply, wallet pay, cash confirm/staff confirm), schedule `POST /v1/internal/invoices/render`. Payment HTTP does not wait on PDF (NFR-PERF-007). `render` is idempotent (`second_render_keeps_version_one`).
- `FileStorage.put` writes `invoices/{bookingId}/v{n}.pdf`. GET `/v1/invoices/{bookingId}` returns metadata + signed download URL. Owner or staff; other customers get 403. Clients cannot write `invoices` in Firestore.
- Invoice screen loads by booking id (no `mockInvoices.first`). Download + share via `share_plus` 11.0.0 (`SharePlus.instance.share` of the PDF file). Reason pinned: share the invoice file.
- Named tests: `invoice_total_matches_payment`, `second_render_keeps_version_one`, `customer_cannot_read_another_invoice`. Widget tests: missing booking id shows loading then error; `b-paid` shows that total.

Left / follow-ups:

- Firestore adapter for `InvoiceRepository` (in-memory fake is the default).
- Real Cloud Storage `put` adapter (fake stores bytes in memory).
- Emailing the PDF, credit notes / explicit v2 re-render API, membership invoices.

Not run locally:

- Firestore rules tests (`firebase/tests/rules.test.js`): no Java. CI installs Java 21.
- App not built for Android or iOS here.

Next: PR against `main`. Do not merge. Do not start M08/M14/M15/M16 in this worktree.

## M14 notes

Branch: `feat/m14-dashboard` from `origin/main` (eba138d, Wave 5 M08+M11). Isolated worktree. FR-USR-001/002/003/006/007/009, FR-VEH-005.

Done:

- Home cards bind to `BookingApi.listMine` and the primary vehicle. Empty home is "Book a service", not a mock job. Wallet tile has no invented rupee total.
- History tabs Upcoming / Active / Past, pull to refresh, empty copy "No services yet." Book again on a paid job prefills vehicle, service, and address. Date stays empty. Quote API recalculates price (`repeat_recalculates_price`).
- Profile edit (name 2–60, optional email, phone read-only). Addresses GET/POST/PATCH/DELETE `/v1/addresses` (PIN 6 digits, max 10). Emergency contacts GET/POST/DELETE `/v1/me/contacts` (max 3). Extended `AddressRepository` and `UserRepository`. No new port.
- Health is a pure function of last paid/completed service date: good ≤90 days, fair ≤180, poor otherwise. Same score on every category. Copy: "Based on your last service. A full checkup will replace this."
- Tracking share sheet lists emergency-contact names as suggested recipients. Creates the M08 token only. Does not SMS.

Named tests: `health_good_within_90_days`, `repeat_recalculates_price`, `address_requires_pincode`, `max_three_emergency_contacts`, `home_does_not_invent_a_wallet_total`.

Shared files (additive slices only): `backend/app/api/deps.py`, `app/lib/composition/providers.dart`, `app/lib/navigation/*`, `backend/openapi.json` + generated Dart.

Out of this PR: loyalty earn/burn, fuel/membership/referral/documents backends, home visual redesign, admin, disputes (M15), invoice PDF, RTDB rules, payments apply.

Not run locally: Firestore/RTDB rules tests (no Java). App not built for Android/iOS here.

## M15 notes

Split: API + named tests on `feat/m15-admin` (this PR). Admin web + "Report a problem" on `feat/m15-admin-ui`. Both `--base main`, same spec [M15-admin.md](milestones/M15-admin.md). Handwritten backend exceeded ~1,500 lines.

Requirements: FR-ADM-001..009.

Done (PR 1 API):

- Ports: `DisputeRepository`, `AnalyticsService` (log adapter). `AuditLog.list_recent` is read-only.
- Admin routes: users/search + suspend, verification applications, bookings filter, revenue from the payment ledger, coupon CRUD (no edit after redemptions), disputes note/resolve, audit, analytics counts.
- Customer `POST /v1/bookings/{id}/disputes` after arrived. Second open conflicts.
- Support can note and cannot refund/resolve. Admin refund reuses M10 and writes audit. Suspended users get `403 account_suspended` on booking create.
- Server `AnalyticsService.track` drops forbidden properties (phone, token, …) and records booking/payment/dispatch events.
- Named tests: `support_cannot_resolve_with_refund`, `suspend_blocks_booking_create`, `coupon_with_redemptions_cannot_be_edited`, `analytics_drops_phone_property`, `dispute_second_open_conflicts`. RBAC is asserted on the API, not only hidden buttons.

Done (PR 2 UI):

- `main_admin.dart` Flutter web, 1024 px width gate ("Use a larger screen"), queues (users, verification, orders, revenue, coupons, disputes, audit). Support buttons are hidden; API still 403s.
- Booking details "Report a problem" only after arrived. Widget test matches that name.
- Admin target does not import maps/camera/image_picker/firebase_database.

Not run locally:

- Firestore rules tests (`firebase/tests/rules.test.js`): no Java. CI installs Java 21.
- Admin Chrome full web build. `flutter analyze` is clean; width-gate widget test passes.

Next: open both PRs against `main`. Do not start M14/M16 in this worktree.

## M16 notes

Branch: `chore/m16-hardening` from `origin/main` (80121a2, Wave 6 M14+M15). Isolated worktree. NFR-A11Y, NFR-I18N-002, NFR-BAT, chapters 16 and 21.

The MVP spec is implemented. Remaining work is owner-only launch (staging soak, store, lawyer, live keys). See [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).

Done:

- Semantics on the pay button and SOS control. Icon-button tooltips on booking, tracking, payment, and SOS back controls. Price total still readable at 1.6 text scale. `textTertiary`/`textHint` bumped to AA on the dark background.
- Hindi ARB for booking, tracking, payment, and SOS. English copy on those buttons is unchanged.
- CI secret scan (`python tool/check_secrets.py`). Named test `secret_scan_fails_on_a_fixture`.
- Chapter 16 HTTP rate limits: booking create 10/hour, payment create 10/hour, admin writes 60/min, public tracking 60/min/IP, webhook 300/min/IP. CORS allow-list (never `*`). Chat and OTP limits stay in their existing use cases/adapters.
- Onboarding "I am 18 or older" stores `adultConfirmedAt` locally. Privacy policy placeholder `https://mechupp.example/privacy` in settings. Demo OTP hint is off in release builds (`kReleaseMode` and non-dev env).
- Checklist tells the owner not to ship `com.example` (current id is `com.mechupp.app`) and not to ship sandbox payment keys. k6/locust notes against `/health` and quote.

Named tests: `semantics_on_the_pay_button`, `semantics_on_the_sos_control`, `hi_locale_loads_the_booking_confirm_button`, `secret_scan_fails_on_a_fixture`, `eleventh_payment_create_is_rate_limited`.

Filed as issues, not this PR:

- Persist `adultConfirmedAt` on `users/{id}` (local speed bump only here).
- SOS 3-failed-in-24h `sos_limited`.
- FastAPI OTP request limit (Firebase/adapter already caps resend).

Not run locally: Firestore/RTDB rules tests (no Java). App not built for Android/iOS here. OS language/text-scale toggle is a manual check.

No new ports. No production deploy.
