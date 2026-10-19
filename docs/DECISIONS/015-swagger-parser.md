# ADR-015 — Generate the Dart client with swagger_parser

**Status:** accepted. **Date:** 2026-10-19.

ADR-012 requires a generated client but names no tool. `openapi-generator` needs Java, which some dev machines and the Windows setup here do not have.

**Decision:** Use `swagger_parser` (pure Dart) to emit Retrofit clients and `json_serializable` models from `backend/openapi.json`. `build_runner` writes the `.g.dart` files. Output lives in `app/lib/core/api/generated/` and is committed. `tool/generate_api_client.{ps1,sh}` runs the whole chain. The `api-client` CI job regenerates and fails on any diff.

**Why this and not the alternatives:** `openapi-generator` adds a JVM dependency to every contributor. Hand-written DTOs drift (ADR-012).

**Consequences:** New packages: `retrofit`, `json_annotation`, and dev-only `swagger_parser`, `retrofit_generator`, `json_serializable`, `build_runner`. Generated types are imported only by the HTTP adapters (`HttpAccountApi` today). Widgets and use cases see domain types. Swapping the generator later changes only the generated folder and the adapters.
