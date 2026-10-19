# ADR-014 — The server is the only writer for status and money

**Status:** accepted. **Date:** 2026-10-19.

A phone that can mark itself paid, or mark a job complete, will be abused the first time a client bug or a modified app appears.

**Decision:** Security Rules deny client writes on those fields. FastAPI uses the Admin SDK. The phone's Cashfree SDK success callback only changes the screen to "Waiting for confirmation."

**Why this and not the alternatives:** "The API double-checks later" still leaves a window where the UI and the database lie. Client writes are simpler to code and they are the wrong trade.

**Consequences:** Emulator tests must try the illegal write and fail. Mark-read for notifications is an API call too, so rules stay uniform. Live location is the documented exception.
