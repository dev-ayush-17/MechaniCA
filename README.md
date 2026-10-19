# MechaniCA

On-demand mechanic booking and roadside assistance for two-wheelers and four-wheelers in India. A customer books a verified mechanic who comes to their location, follows them live, pays, and gets a GST invoice. Mechanics and admins use the same codebase through separate entrypoints.

This repository is in specification phase. The Flutter app under `mechanica_app/` is a static demo. The FastAPI file under `mechanica_api/` is a mock login stub. Application code is not changed until milestone M00.

## Read this first

| Doc | Purpose |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Rules for humans and coding agents |
| [docs/PRD.md](docs/PRD.md) | Product and architecture index |
| [docs/MILESTONES.md](docs/MILESTONES.md) | Build order |
| [docs/LEARNING_NOTES.md](docs/LEARNING_NOTES.md) | How a request moves through the system |
| [docs/AGENT_PROGRESS.md](docs/AGENT_PROGRESS.md) | Where the last session stopped |

## Layout today

```
mechanica_app/     Flutter demo (moves to app/ in M00)
mechanica_api/     FastAPI stub (moves to backend/ in M00)
docs/              PRD, ADRs, milestones
.cursor/rules/     Agent rules
```

Target layout after M00: `app/`, `backend/`, `firebase/`, `docs/`.

## Run the demo (unchanged)

```bash
cd mechanica_app
flutter pub get
flutter run
```

Sign-in accepts the demo OTP `123456`. Nothing is saved on a server.

## Status

Phase 0 is documentation and governance. The first implementation milestone is M00 (tooling, layout, emulator, fake adapters). Do not deploy Firebase or Cloud Run from this repository until that milestone says so.
