# ADR-011 — Monorepo folders

**Status:** accepted. **Date:** 2026-10-19.

The repo has `mechanica_app/` and `mechanica_api/` at the root.

**Decision:** M00 uses `git mv` to create `app/`, `backend/`, and `firebase/`. `docs/` already exists. History must be preserved. Do not copy and delete.

**Why this and not the alternatives:** A big-bang manual copy looks like a new project in git blame. Leaving the old names makes every doc and CI path a special case forever.

**Consequences:** The move is its own commit. The demo must still run from `app/` before M00's PR merges. Import paths inside Dart are package imports (`package:mechanica_app/...`) and should not all break if the folder moves and the package name stays. If the package is renamed, that is a separate commit in M00 with a reason.
