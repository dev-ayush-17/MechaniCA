# Agent progress

Living log. Update this at the end of every session.

## Current

| Field | Value |
| --- | --- |
| Phase | Implementation |
| Branch | `refactor/m01-frontend-foundations` (stacked on `chore/m00-foundation`, PR #4) |
| Milestone in progress | M01 frontend foundations. Code and tests are done. Awaiting review. M00 awaits review (PR #4) |
| Next milestone | M02 auth (runs in parallel on `feat/m02-auth`), then M03 |
| Demo | Runs from `app/` with `flutter run`. Screens are unchanged. Mock providers are re-exported by `app/lib/composition/providers.dart` |
| Known broken | Nothing known. `flutter analyze` reports no issues |

## Completed

| When | What |
| --- | --- |
| 2026-10-19 | Frontend audit on `main` (`069f045`). Flutter 3.44.6, Dart 3.12.2. `flutter analyze`: 160 issues, 1 error (`MyApp` in `widget_test.dart`) |
| 2026-10-19 | PRD chapters 01–25, ADRs 001–014, agent rules, milestone specs (PR #3) |
| 2026-10-19 | M00: `git mv` to `app/` and `backend/` (191 renames, no content change) |
| 2026-10-19 | M00: backend skeleton. `/health` and `/health/ready`, settings, JSON logging with redaction, `Clock` and readiness ports with fakes, `deps.py` composition root. Ruff, mypy strict, 4 pytest tests pass. The fake-JWT login stub is deleted |
| 2026-10-19 | M00: `firebase/` emulator config, deny-by-default Security Rules, rules tests (written, see below) |
| 2026-10-19 | M00: Flutter core (`Result`, `AppFailure`, `Clock`, `Logger`, `FeatureFlags`, `AppConfig`) and `composition/providers.dart`. 5 tests pass |
| 2026-10-19 | M00: `tool/check_import_boundaries.py` with unit tests, `.githooks/` with smoke tests, `.github/workflows/ci.yml` |

| 2026-10-19 | Product rename chore to MechUpp: identifiers, package names, Android com.mechupp.app, iOS display name/bundle id, env prefix MECHUPP_, emulator project id demo-mechupp, ADR-016. |

## M01 notes and follow-ups

- `intl` moved 0.19.0 to 0.20.2 because `flutter_localizations` pins it.
- The analyzer fixes touched `features/auth/login_screen.dart`, `onboarding_screen.dart` and `forgot_password_screen.dart` (one-line const and mounted fixes). Expect a trivial merge with M02.
- `assets/` is not declared in pubspec (no asset is referenced). Add the block back with the first real asset.
- Behavior-adjacent analyzer fixes: `context.mounted` guards before snackbars and pop in save handlers, a `mounted` guard after the coupon delay, and the write-only `_isRefreshing` field removed from Home. No visible change intended.
- Not done: moving strings into `app_en.arb` (only the catalog exists; no screen reads it yet). Do it per feature milestone.
- Manual walk of tabs, fuel, membership, refer, and documents was not run (no device here). Only the widget test covers splash then onboarding.

## Not verified locally

- Firestore rules tests (`firebase/tests/rules.test.js`) were **not run**. This machine has no Java, which the Firestore emulator needs. The `firebase-rules` CI job installs Java 21 and runs them. Treat that job as the first real run and fix any failure before relying on the rules.
- CI workflow YAML has not run on GitHub yet.

## Deviations from the M00 spec

- Commit linting uses a shell `commit-msg` hook, not Node commitlint. Reason: Flutter and Python contributors would otherwise need Node for a regex. Same rule, no dependency.
- The Dart package is still named `mechanica_app`. Renaming it touches every import and belongs with the milestone that owns each feature.

## Decisions already made

See [DECISIONS/README.md](DECISIONS/README.md). Do not re-litigate them inside a milestone unless you write a new ADR.

## Open items that do not block the next milestone

- Product rename to MechUpp (done in `chore/rename-to-mechupp`, ADR-016).
- Production Firebase and GCP projects (owner). Do not create them from an agent session.
- Cashfree and Google Maps keys (owner). Fakes until then.
- Final auth vendor if not Firebase (default adapter is Firebase phone OTP).
- Masked-call vendor (M12 may ship with the Call button flagged off).
- Owner: enable GitHub branch protection on `main`. The local `pre-push` hook is only a safety net.

## M02 auth (branch `feat/m02-auth`, built in parallel with M01)

**This branch was cut from `chore/m00-foundation`, not from M01. Rebase it onto M01 after M01 merges, then re-run `flutter analyze`, `flutter test`, and the codegen drift check.** Expect conflicts in `app/pubspec.yaml`, `app/pubspec.lock` (regenerate with `flutter pub get`), `app/lib/providers/app_providers.dart`, `app/lib/navigation/app_router.dart`, and this file.

Status: all six tasks in [milestones/M02-auth.md](milestones/M02-auth.md) are done. Awaiting review. Not started: M03.

| What | Where |
| --- | --- |
| Ports `AuthVerifier`, `UserRepository`, plus `RoleClaims` (bootstrap must write the claim the verifier reads) | `backend/app/ports/` |
| Fakes: `FakeAuth` (token `fake:<uid>:<phone>`, dev and test only), `FakeUserRepository` | `backend/app/adapters/fake/` |
| Firebase Admin adapter, loaded only when `MECHANICA_PROVIDER_AUTH=firebase` | `backend/app/adapters/firebase/auth_verifier.py`, bound in `api/deps.py` |
| `POST /v1/me/bootstrap` (201 first time, 200 on repeat, role from `intent`, never from the body), `GET /v1/me`, one error envelope with `X-Request-Id` | `backend/app/api/v1/me.py`, `api/errors.py`, `application/bootstrap_user.py` |
| `Settings` refuses `provider_auth=fake` unless `app_env` is dev or test | `backend/app/core/config.py` |
| OpenAPI export and generated Dart client ([ADR-015](DECISIONS/015-swagger-parser.md)) | `backend/openapi.json`, `app/lib/core/api/generated/`, `tool/generate_api_client.*`, CI job `api-client` |
| Flutter `AuthService` port, `FakeAuthService` (123456 only when `APP_ENV=dev`, 30 s resend, 5 sends per hour, 5 failures lock 15 min), `FirebaseAuthService` under `data/adapters/` | `app/lib/features/auth/` |
| `AccountApi` port with `HttpAccountApi` (generated client, one refresh on 401) and `FakeAccountApi` (offline demo) | `app/lib/features/auth/` |
| Session restore at splash. The fake stores only the fake phone in SharedPreferences, in dev | `splash_screen.dart`, `fake_session_store.dart` |
| `/forgot-password` removed. Permission screens moved to `permission_screens.dart` | `app/lib/navigation/`, `features/auth/presentation/` |

Deviations and decisions:

- `AuthService.currentSession` is async and takes `forceRefresh`, because platform storage and token refresh are async. Port catalog says sync.
- `UserRepository` has `get` and `upsert` only. `suspend` waits for the admin milestone.
- The login screen's Continue button is disabled until the number has 10 digits, the Google button is hidden while `auth_google_enabled` is off, and the demo hint shows only when `APP_ENV=dev`. All three are required by the M02 spec.
- Moved `login_screen`, `otp_screen`, `splash_screen` to `features/auth/presentation/`. `onboarding_screen` stays where it is until a milestone touches it.
- `AccountApi` follows `PROVIDER_AUTH`: the fake binding uses the offline `FakeAccountApi`, so the demo works with no server running.

Follow-ups, not done here (scope):

- **Mechanic draft profile.** The spec says mechanic intent creates a draft profile. The Mechanic entity and repository do not exist yet, so bootstrap only sets role `mechanic`. Create the draft in the mechanic onboarding milestone.
- **Firestore `UserRepository`.** Only the in-memory fake exists, so users are lost when the API restarts and `PROVIDER_AUTH=firebase` is not usable end to end until the Firestore adapter lands. Add it with a rules test.
- **Global 401 redirect.** A 401 on restore signs out and shows onboarding. Redirecting from any later API call needs the router to watch auth state. Add it with the first screen that calls the API after login.
- `check_revoked=true` is supported by the verifier port but no route requests it yet (payments and role changes will).
- Google sign-in stays `provider_disabled`.
- Mechanic entrypoint passes `AccountIntent.mechanic`; not wired because there is no second entrypoint yet.

Not verified locally:

- `FirebaseAuthService` and `FirebaseAuth` (Admin SDK) have not run against the Firebase Auth emulator. This machine has no Java. Only the error-code mapping is unit tested. Run both against the emulator before turning `PROVIDER_AUTH=firebase` on.
- The app was not built for Android or iOS here. `firebase_core` and `firebase_auth` add native plugins and need `google-services.json` (not committed) before `PROVIDER_AUTH=firebase` can start.
- The new `api-client` CI job has not run on GitHub.

Manual check (fake binding, `flutter run --dart-define-from-file=config/dev.json`): sign in with any 10-digit number and `123456`, kill the app, relaunch, land on home. Sign out from Profile, land on login.

## M03 vehicles

Status: **merged** to `main` (PR #9).

| What | Where |
| --- | --- |
| Freezed `Vehicle`, Indian plate validation, `/bikes` UI under `features/vehicles/` | `app/lib/features/vehicles/` |
| `GET/POST/PATCH/DELETE /v1/vehicles`, fake + Firestore vehicle repositories | `backend/app/api/v1/vehicles.py`, adapters |
| Drift `LocalVehicles` + `SyncQueueEntries` (vehicle kinds only) | `app/lib/data/local/` |

Follow-ups: Firestore `UserRepository` on the API (M02 note); full vehicle POST idempotency replay later.

## M04 mechanics (branch `feat/m04-mechanics`)

Status: implementation complete. PR #8; merging after M03 reconciliation on shared files.

| What | Where |
| --- | --- |
| Mechanic API (`/v1/mechanic/*`, `/v1/uploads/sign`, admin verification) | `backend/app/api/v1/mechanic.py`, `admin_verification.py` |
| Ports `MechanicRepository`, `FileStorage`, `AuditLog` with fakes | `backend/app/ports/`, `backend/app/adapters/fake/` |
| Mechanic entrypoint and onboarding | `app/lib/main_mechanic.dart`, `app/lib/features/mechanic_onboarding/` |
| Customer profile mechanic-role banner | `app/lib/features/profile/profile_screen.dart` |
| Firestore mechanics + documents rules | `firebase/firestore.rules`, `firebase/tests/rules.test.js` |

## Next session

Merge M04 PR #8 after CI on the merged branch. Then M05 per [MILESTONES.md](MILESTONES.md).
