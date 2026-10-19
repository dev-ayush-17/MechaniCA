# MechaniCA

On-demand mechanic booking and roadside assistance for two-wheelers and four-wheelers in India. A customer books a verified mechanic who comes to their location, follows them live, pays, and gets a GST invoice. Mechanics and admins use the same codebase through separate entrypoints.

The Flutter app under `app/` is still a static demo. The FastAPI service under `backend/` is a skeleton (health endpoints, config, logging). Features arrive milestone by milestone.

## Read this first

| Doc | Purpose |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Rules for humans and coding agents |
| [docs/PRD.md](docs/PRD.md) | Product and architecture index |
| [docs/MILESTONES.md](docs/MILESTONES.md) | Build order |
| [docs/LEARNING_NOTES.md](docs/LEARNING_NOTES.md) | How a request moves through the system |
| [docs/AGENT_PROGRESS.md](docs/AGENT_PROGRESS.md) | Where the last session stopped |

## Layout

```
app/               Flutter (Dart package is still named mechanica_app)
backend/           FastAPI on Cloud Run
firebase/          Security Rules, emulator config, rules tests
tool/              Repo checks (import boundaries, hook tests)
docs/              PRD, ADRs, milestones
.cursor/rules/     Agent rules
.githooks/         commit-msg and pre-push hooks
```

## Run the demo (unchanged)

```bash
cd app
flutter pub get
flutter run
```

Sign-in accepts the demo OTP `123456`. Nothing is saved on a server.

## Backend, Firebase, and checks

```bash
# backend (Python 3.12)
cd backend && python -m venv .venv && .venv/Scripts/activate  # or source .venv/bin/activate
pip install -e ".[dev]"
ruff check . && mypy app && pytest -q
uvicorn app.main:create_app --factory --reload

# Firebase Security Rules tests (needs Java 21 and Node 22)
cd firebase && npm ci && npm test

# vendor-import boundary check
python tool/check_import_boundaries.py
```

## Git hooks

Install once per clone:

```bash
git config core.hooksPath .githooks
```

`commit-msg` enforces Conventional Commits with a subject of 72 characters or fewer. `pre-push` blocks pushes to `main`, remote branch deletion, and force pushes. Fix the cause when a hook fails. Do not skip hooks. Branch protection on GitHub is the real control, so enable it on `main`.

## Status

M00 (layout, backend skeleton, emulator config, CI, hooks) is done. Next is M01. Do not deploy Firebase or Cloud Run from this repository until that milestone says so.
