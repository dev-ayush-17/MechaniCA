# 22 — Coding standards

These are the engineering rules for every milestone. `AGENTS.md` repeats the short form.

## Calibration

- **Justify complexity.** Every new layer, package, or pattern needs a concrete reason: a requirement, a likely vendor swap, or a test. If you cannot name it, do not add it.
- **Abstract at real boundaries.** Auth, payments, maps, notifications, storage, and data access are behind ports. Do not wrap Dart `String` or FastAPI's `APIRouter` in an interface. Do not add an interface that has one trivial implementation inside the domain.
- **Rule of three.** Do not extract a shared helper the first time. The third copy is the signal. Wrong abstractions are more expensive than duplication.
- **Never trade safety for simplicity.** Keep validation at the boundary, typed errors, idempotency on money and bookings, server-side authorization, tests on the critical paths, and a visible failure state in the UI.
- **Keep it understandable.** A new teammate should find a feature by folder name and follow it from the screen to the adapter. Prefer boring tools.
- **Prefer maintained libraries** for solved problems. Pin versions. One line in the PR says why the dependency was added.

## Dart and Flutter

- Feature folders: `features/<name>/{presentation,domain,data}`.
- Immutable models with `freezed` once the feature is touched.
- `Result` for expected failures. Exceptions are for programmer errors.
- No `catch (_) {}`. Catch the typed failure and show it, or rethrow.
- No business rules in `build` methods. A coupon check in a widget is a bug.
- New or touched user-facing strings go through ARB.
- `analysis_options.yaml` will grow in M01 to the `flutter_lints` set plus `avoid_print`, `prefer_const_constructors`, and the import boundary. Do not `// ignore` a lint to finish a milestone unless the line says why.

## Python

- Ruff format and lint. Mypy on domain and application.
- Routers are thin: parse, call a use case, map errors.
- Pydantic models are the HTTP boundary. Domain models are separate. A mapper converts them.
- No `except Exception: pass`.

## Both

- Vendor SDK imports only inside adapter directories. CI fails otherwise.
- Config for keys, URLs, fee amounts, and provider names. No `if provider == "cashfree"` inside a use case. The binding already chose the adapter.
- Comments explain why, not what the next line does.

## UI

- Keep the current dark theme and the red primary unless a contrast check fails.
- Reuse `AppButton`, `EmptyState`, and `ErrorState` instead of copying them.
- Every screen that loads has loading, empty, error, and offline outcomes if the data can be missing or the call can fail.
- Do not redesign a screen because a newer style looks better. File that as a backlog note.

## Git

Follow chapter 21. Small commits. Refactors separated from behavior.

## Done

A change is done when the milestone's definition of done is checked, the demo still runs, tests named in the milestone exist and pass, and `docs/AGENT_PROGRESS.md` says what finished.
