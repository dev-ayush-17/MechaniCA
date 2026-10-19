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

| 2026-10-19 | M01: widget test pumps `MechaniCAApp` and checks splash then onboarding. Deleted `lib/screens`, `lib/theme`, and two unreferenced permission screens. Dropped 5 unused packages and the missing asset dirs. Direct deps pinned to the locked versions. `flutter analyze`: no issues (was 160). l10n scaffold (`l10n.yaml`, `app_en.arb`, delegates in `main.dart`). `avoid_print` and `prefer_const_constructors` enabled |

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

- Product rename to MechUpp (default: no).
- Production Firebase and GCP projects (owner). Do not create them from an agent session.
- Cashfree and Google Maps keys (owner). Fakes until then.
- Final auth vendor if not Firebase (default adapter is Firebase phone OTP).
- Masked-call vendor (M12 may ship with the Call button flagged off).
- Owner: enable GitHub branch protection on `main`. The local `pre-push` hook is only a safety net.

## Next session

Start M01 from [milestones/M01-frontend-foundations.md](milestones/M01-frontend-foundations.md). Branch `refactor/m01-frontend-foundations` from `chore/m00-foundation`.
