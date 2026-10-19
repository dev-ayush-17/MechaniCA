# ADR-007 — Realtime Database for live location

**Status:** accepted. **Date:** 2026-10-19.

Location updates are small, frequent, and disposable. Booking documents are not.

**Decision:** Firestore stores bookings and the rest of the domain. RTDB stores `liveLocations/{bookingId}` and mechanic presence. Clients may write only their own location node while a gate document says the job is open.

**Why this and not the alternatives:** Writing a Firestore document every five seconds costs more and fights the "no client writes" rule if we are not careful. Putting bookings in RTDB would make queries and transactions worse. Polling the API for GPS would add load and latency.

**Consequences:** Security Rules for RTDB are tested. A nightly job deletes old nodes. The domain port hides which database is used.
