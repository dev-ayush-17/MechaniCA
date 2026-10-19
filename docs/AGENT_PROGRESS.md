# Agent progress

Living log. Update this at the end of every session.

## Current

| Field | Value |
| --- | --- |
| Phase | 0 — specification |
| Branch | `docs/prd-and-milestones` |
| Pull request | https://github.com/dev-ayush-17/MechaniCA/pull/3 |
| Milestone in progress | None. Phase 0 spec is written on this branch |
| Next implementation milestone | M00 foundation, after this PR merges |
| Demo | Unchanged. `mechanica_app` still mock-only. Widget test still broken on purpose until M01 |
| Coverage check | Every `FR-*` id is in [MILESTONES.md](MILESTONES.md). FR-USR-008 is explicitly not built. The dependency graph has no cycle |

## Completed

| When | What |
| --- | --- |
| 2026-10-19 | Frontend audit on `main` (`069f045`). Flutter 3.44.6, Dart 3.12.2. `flutter analyze`: 160 issues, 1 error (`MyApp` in `widget_test.dart`) |
| 2026-10-19 | PRD chapters 01–25, ADRs 001–014, agent rules, milestone specs |

## Decisions already made

See [DECISIONS/README.md](DECISIONS/README.md). Do not re-litigate them inside a milestone unless you write a new ADR.

## Open items that do not block M00

- Product rename to MechUpp (default: no).
- Production Firebase and GCP projects (owner). Do not create them from an agent session.
- Cashfree and Google Maps keys (owner). Fakes until then.
- Final auth vendor if not Firebase (default adapter is Firebase phone OTP).
- Masked-call vendor (M12 may ship with the Call button flagged off).

## Next session

Start M00 only after the Phase 0 PR is merged. Paste the execution prompt from [milestones/M00-foundation.md](milestones/M00-foundation.md).
