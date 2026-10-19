# AGENTS.md

MechUpp is an on-demand mechanic service for India. Spec: [docs/PRD.md](docs/PRD.md). Build order: [docs/MILESTONES.md](docs/MILESTONES.md). Resume from [docs/AGENT_PROGRESS.md](docs/AGENT_PROGRESS.md).

## Stack

Flutter (Dart 3) customer, mechanic, and admin-web entrypoints. FastAPI (Python 3.12) on Cloud Run. Firebase Auth, Firestore, Realtime Database (live location only), Storage, FCM. Cashfree and Google Maps behind adapters. No Cloud Functions.

Layout: `app/` (Flutter; the Dart package is named `mechupp_app`), `backend/` (FastAPI), `firebase/` (rules, emulator config), `tool/` (repo checks).

## Architecture

- Domain code does not import Firebase, Cashfree, Google Maps, or other vendor SDKs.
- Those SDKs live only under adapter directories.
- One composition root per process: `composition/providers.dart` (Riverpod) and `backend/app/api/deps.py` (`Depends`).
- Swapping a provider means a new adapter and one config binding. No UI or use-case edits.
- Clients may read Firebase. Only FastAPI writes booking status, prices, payments, wallet, coupons, rating aggregates, and verification.
- Clients may write only their own live-location node, and only while the API has opened that gate.
- FastAPI OpenAPI is the contract. The Dart client is generated.

## Calibration

- Justify every new layer or package in one line, or do not add it.
- Abstract auth, payments, maps, notifications, storage, and data access. Do not wrap stable language features.
- Do not extract a shared helper before the third copy.
- Never drop validation, typed errors, idempotency on money and bookings, server authorization, critical tests, or visible error states to "keep it simple."
- A new teammate should find a feature by its folder and follow it end to end.
- Prefer a maintained library over custom code for a solved problem. Pin the version.

## Refactoring the demo

You may restructure the Flutter demo. Do it safely:

- The app must build and run after every commit.
- Add a characterization test before refactoring a screen, when that is practical.
- One feature at a time. M01 is foundations only. Later milestones clean the feature they touch.
- `refactor` commits stay separate from `feat` and `fix` commits.
- Keep the current look unless it is broken. Propose redesigns as backlog notes.
- Delete dead code through the normal commit flow.
- Record a structural change as an ADR in `docs/DECISIONS/`.
- Do not suppress analyzer lints without a reason on the same line.

## Git

- Never commit on `main`. Branch names: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/`, `test/` plus a scope.
- Conventional Commits. Subject ≤ 72 characters. Body says why.
- Do not use `--force`, `--no-verify`, `git reset --hard`, or history rewriting.
- Do not commit `.env`, service-account JSON, pem, or p12 files.
- Do not `firebase deploy`, `gcloud run deploy`, or delete cloud resources. Use the emulator.
- Open a PR. Do not merge your own work to `main` unless the milestone and the owner say so.

## Commands

`flutter analyze` and `flutter test` in `app/`. `ruff check`, `mypy`, and `pytest` in `backend/`. Repo checks: `python tool/check_import_boundaries.py`. Hooks: `git config core.hooksPath .githooks`. The stock widget test is known broken; M01 replaces it.

## Definition of done

The milestone checklist is complete, named tests pass, the demo still runs, docs that the change invalidates are updated, and `docs/AGENT_PROGRESS.md` records the stop point.

## Never

- Vendor SDK imports outside adapters.
- Client writes of status or money, including "temporary" ones.
- A second booking or charge on retry. Use the idempotency key.
- Marking a payment paid because the phone SDK returned success.
- Logging OTP, tokens, webhook bodies, or card data.
- Expanding a milestone because a nearby refactor looked easy. File an ADR or a PRD note instead.
- Treating the demo's workshop statuses (`pickedUp`, `inWorkshop`, `outForDelivery`) as the product. The product state machine is in `docs/prd/13-state-machines.md`.
