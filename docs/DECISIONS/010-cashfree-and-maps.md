# ADR-010 — Cashfree and Google Maps behind ports

**Status:** accepted. **Date:** 2026-10-19.

The owner named Cashfree and Google Maps. Account keys are not in the repo.

**Decision:** `PaymentGateway` and `MapsService` are the only way use cases talk to those products. Dev uses fakes. The app never collects card numbers.

**Why this and not the alternatives:** Calling the SDKs from widgets would make a vendor change a UI rewrite. The owner still has to supply keys, and the abstraction keeps that wait off the critical path.

**Consequences:** Wallet and cash do not go through Cashfree. Online methods do. Map tiles may use the client SDK. Route and geocode calls go through the port so tests do not need a key.
