# ADR-012 — Generate the Dart client from OpenAPI

**Status:** accepted. **Date:** 2026-10-19.

The app and the API will drift if both sides hand-write DTOs.

**Decision:** FastAPI's OpenAPI schema is the source of truth. CI generates the Dart client and fails if the committed client is stale. Generation starts in M02, when the first real route exists. M00 only serves `/health`.

**Why this and not the alternatives:** A hand-written Dio client will diverge the first time a field is renamed. Sharing Python models into Dart is not practical.

**Consequences:** The HTTP adapter maps generated DTOs into domain entities. Widgets do not import generated types. Additive JSON fields are fine. Breaking fields need `/v2` or a deprecation window.
