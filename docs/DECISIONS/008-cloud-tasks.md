# ADR-008 — Cloud Tasks and Scheduler

**Status:** accepted. **Date:** 2026-10-19.

Dispatch timeouts, extra-work timeouts, and payment reconciliation need a clock that is not a phone.

**Decision:** Cloud Tasks calls FastAPI at a specific time for per-booking delays. Cloud Scheduler calls FastAPI on a cron for sweeps. A one-minute sweeper also expires offers whose task failed to enqueue. No Cloud Functions. Pub/Sub is not the timer.

**Why this and not the alternatives:** Pub/Sub does not fire at "45 seconds from now" by itself. Cloud Functions would be a second backend the team would have to secure. In-process timers die when Cloud Run scales down.

**Consequences:** Job handlers are idempotent and authenticated with OIDC. The fake `JobScheduler` runs due jobs inside tests.
