# ADR-013 — Offer a job to one mechanic at a time

**Status:** accepted. **Date:** 2026-10-19.

SOS feels faster if five mechanics are pinged at once. It also creates double accepts and a messy cancel story.

**Decision:** Sequential offers. Normal timeout 45 seconds. SOS timeout 20 seconds. Two reassignments, then `failed`. Rank by distance, rating, acceptance, and recent offer count.

**Why this and not the alternatives:** Fan-out needs a locking design we should not invent under time pressure. One winner is easy to test. If field data shows SOS is too slow, Phase 2 can add fan-out with a new ADR.

**Consequences:** The customer sees "still looking" between attempts. The server task is authoritative. The phone countdown is a hint.
