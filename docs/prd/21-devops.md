# 21 — DevOps

M00 implements the tooling this chapter describes. This phase only writes the policy.

## Environments

| Env | Flutter define | API | Firebase | Payments | Maps |
| --- | --- | --- | --- | --- | --- |
| dev | `APP_ENV=dev` | localhost or emulator | Emulator suite | fake | fake |
| staging | `staging` | Cloud Run staging URL | staging project | Cashfree sandbox | a restricted key |
| prod | `prod` | Cloud Run prod URL | prod project | Cashfree live | a restricted key |

The app refuses to start a release build if `APP_ENV=prod` and `API_BASE_URL` contains `localhost` or `10.0.2.2`.

There is one Firebase project per environment when the owner creates them. Until then, everyone uses the emulator. Agents do not run `firebase deploy` or `gcloud run deploy`.

## Secrets

| Secret | Where it lives |
| --- | --- |
| Cashfree app id and secret | Secret Manager, or a local untracked `.env` for staging experiments |
| Maps server key | Secret Manager |
| Maps client key | Flutter flavor config, restricted by package name and SHA. Still not committed |
| Firebase Admin | Cloud Run service account. No JSON key in prod |
| Webhook secret | Secret Manager |
| Local emulator | No secret. `firebase emulators:start` |

Files that must stay untracked: `.env`, `.env.*` except `.env.example`, `serviceAccount*.json`, `*.pem`, `*.p12`, `google-services.json`, `GoogleService-Info.plist`. `.env.example` lists keys with empty values and is committed in M00.

## Branching

- `main` is always demo-runnable once M01 lands, and API-health-runnable once M00 lands.
- One branch per milestone slice: `feat/<scope>-<desc>`, `fix/`, `docs/`, `chore/`, `refactor/`, `test/`.
- Merge through a PR. No direct pushes to `main`. Branch protection is an owner setting in GitHub. The pre-push hook in M00 rejects pushes to `main` and rejects `--force` as a local safety net, knowing a determined person can skip a hook. The hook is still worth having.
- Squash or merge commits are both acceptable. Do not rebase shared branches.

## Commits

Conventional Commits. Subject line imperative, max 72 characters. Body says why when the diff is not obvious.

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Examples:

```
feat(booking): reject cancel after the mechanic arrives

refactor(booking): extract the wizard steps without changing copy

docs(prd): specify cash confirmation
```

Refactor commits do not change behavior. Feature commits do not hide a drive-by rename of an unrelated module.

## CI (GitHub Actions), from M00

| Workflow | On | Steps |
| --- | --- | --- |
| `app` | changes under `app/**` or current `mechanica_app/**` until the move | `flutter analyze`, `flutter test` |
| `backend` | `backend/**` | `ruff check`, `mypy`, `pytest` (unit). Emulator job optional on PRs |
| `docs` | `docs/**` | markdown link check if a small tool is easy. If not, skip rather than adding a heavy doc site |

CI does not deploy.

## Code review

- One human approval when another teammate is available. If the owner is solo on a milestone, the PR description still includes the test plan and they may merge. Do not invent a second reviewer.
- Review looks for: business logic in widgets, vendor imports outside adapters, missing idempotency on money, secrets, and tests for the critical case named in the milestone.
- `CODEOWNERS` requests the origin owner.

## Release

Not in this phase. M16 writes the store checklist: version bump, changelog, staging soak, rollback note. Until then, `version` in pubspec stays `1.0.0+1` unless a milestone has a reason to bump it. It does not.

## Local run (target after M00)

```bash
# terminal 1
firebase emulators:start --config firebase/firebase.json

# terminal 2
cd backend && uvicorn app.main:app --reload --port 8000

# terminal 3
cd app && flutter run --dart-define-from-file=config/dev.json
```

Today, before M00:

```bash
cd mechanica_app && flutter pub get && flutter run
```

The demo OTP is `123456`.
