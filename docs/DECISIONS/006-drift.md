# ADR-006 — Drift for offline storage

**Status:** accepted. **Date:** 2026-10-19.

The product caches vehicles, profile, history, and drafts, and it queues a few writes.

**Decision:** Use Drift (SQLite).

**Why this and not the alternatives:** Isar is less of a safe long-term bet. SQLite files are easy to inspect when a sync bug appears. SharedPreferences cannot hold the queue or the history list safely.

**Consequences:** The sync queue kinds are listed in the data model. `booking_create` is not one of them. M03 introduces Drift with vehicles, not with every feature at once.
