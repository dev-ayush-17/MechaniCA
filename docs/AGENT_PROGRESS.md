# Agent progress

Living log. Update this at the end of every session.

## Current

| Field | Value |
| --- | --- |
| Phase | Implementation |
| Branch | `chore/m00-foundation` (stacked on `docs/prd-and-milestones`, PR #3) |
| Milestone in progress | M00 foundation. Code, tests, CI, and docs are done. Awaiting review |
| Next milestone | M01 frontend foundations, stacked on this branch |
| Demo | Runs from `app/` with `flutter run`. Screens are unchanged. Mock providers are re-exported by `app/lib/composition/providers.dart` |
| Known broken | `app/test/widget_test.dart` references `MyApp`. M01 replaces it |

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
