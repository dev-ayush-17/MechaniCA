# M00 — Foundation

## 1. Goal

Make the repo a monorepo a later session can build on, without changing demo screens. Covers the layout and CI parts of [chapter 21](../prd/21-devops.md), NFR-MAIN-002, and NFR-SEC-003.

## 2. Prerequisites

Phase 0 PR merged to `main`. No earlier milestone.

## 3. Scope

In: `git mv` to `app/`, `backend/`, `firebase/`. Python project, Dockerfile, `/health` and `/health/ready`. Delete the fake `POST /login`. Flutter `Result`, `Clock`, `Logger`, `FeatureFlags`, and a composition root that still returns today's mock repositories. Emulator config and deny-all-writes rules for bookings and payments. CI for analyze, ruff, mypy, pytest. Pre-push hook that rejects force pushes and pushes to `main`. commitlint config. `.env.example`. Import-boundary script. Dev JSON flavor file.

Out: auth, vehicles API, screen refactors, real Firebase project, Cashfree, Maps keys, generating a Dart API client (M02).

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `mechanica_app/` | `git mv` to `app/` | `flutter test` after the move. The known `MyApp` failure may remain until M01. `flutter analyze` should not gain new errors |
| `mechanica_api/main.py` | Replace with the package layout. Delete fake login | No live route calls it. Grep for `10.0.2.2` and leave the dead screen for M01 |
| Feature screens | Do not edit | Demo behavior unchanged |

## 5. Tasks

1. `git mv mechanica_app app` and `git mv mechanica_api backend` in one commit. Fix tool paths (README, CI) only.
2. Add `backend/pyproject.toml` (FastAPI, Pydantic v2, uvicorn, pydantic-settings, ruff, mypy, pytest, httpx). Pin versions.
3. Add `app/main.py` factory, `core/config.py`, `api/deps.py`, `GET /health`, `GET /health/ready`.
4. Dockerfile, non-root, port 8080. Do not copy secrets into the image.
5. `firebase/firebase.json` emulator (Auth, Firestore, RTDB, Storage). Rules that deny client writes on `bookings` and `payments`.
6. Dart `core/error/result.dart`, `Clock`, `Logger`, `FeatureFlags`, `composition/providers.dart` re-exporting current mock providers so `main.dart` still boots.
7. `config/dev.json` and `.env.example` with empty keys.
8. Script `tool/check_import_boundaries.dart` (or a small Python scan) failing on `cloud_firestore`, `firebase_database`, `cashfree`, `google_maps` imports outside `data/adapters`.
9. GitHub Actions: Flutter analyze, backend ruff, mypy, pytest.
10. Hook: reject `git push` to `main` and reject force. Document install in README. commitlint on commit messages.
11. Update README run instructions to `app/` and `backend/`.

## 6. Ports

Introduce with fakes only: `Clock`, `Logger`, `FeatureFlags`. No Firebase adapter yet.

## 7. Files

Create the trees in [chapter 07](../prd/07-system-architecture.md). Delete `backend/main.py` stub content after the package exists (the move preserves history; the stub replacement is the next commit). Do not delete Flutter features.

## 8. Branch and commits

Branch: `chore/m00-foundation`.

1. `chore(repo): move app and api into monorepo folders`
2. `chore(backend): add health checks and project tooling`
3. `chore(firebase): add emulator config and deny-write rules`
4. `chore(app): add composition root and core ports`
5. `ci: run analyze and backend checks`
6. `chore(git): reject pushes to main and force pushes`

## 9. Tests

- `test_health_ok`
- `test_ready_reports_dependency` using a fake checker
- `rules_deny_client_booking_write` if the emulator can run in CI. If it cannot, land the test and a documented local command, and do not skip silently without a note in AGENT_PROGRESS
- Unit test: `Logger` drops a field named `token`
- Boundary script fails on a fixture file and passes on the real tree

## 10. Acceptance and manual check

- Given the demo, when you `flutter run` from `app/`, then splash and home still appear and OTP `123456` still signs in.
- Given `uvicorn`, when you open `/health`, then the body is `{ "status": "ok" }`.
- Given a push to `main`, when the hook is installed, then the push is rejected.

Manual: run the three commands in chapter 21's "after M00" section. Open the app. Sign in with `123456`. Open My Bikes. Pull to refresh is not required.

## 11. Definition of done

- [ ] Tasks done. Demo runs. `/health` returns ok.
- [ ] No secrets committed.
- [ ] CI green on the PR.
- [ ] `docs/AGENT_PROGRESS.md` updated.
- [ ] PR opened. Not merged to `main` by the agent unless the owner asked.

## 12. Risks and rollback

The folder move is the risky commit. Revert that commit if `flutter run` breaks and the fix is not obvious in the same session. Do not mix the move with screen edits.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M00 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M00-foundation.md. Follow docs/DECISIONS/011-repo-layout.md. Do not change feature screens. Do not deploy Firebase or Cloud Run. Keep the demo runnable after every commit. Use branch chore/m00-foundation and Conventional Commits. Finish by updating docs/AGENT_PROGRESS.md and opening a PR.
```
