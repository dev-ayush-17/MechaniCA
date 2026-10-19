# ADR-016 — Product name becomes MechUpp

**Status:** accepted. **Date:** 2026-10-19. Supersedes [ADR-001](001-product-name.md).

**Context:** The product name was MechaniCA (with historical demo references to Mechanika). The owner requested a single product name change across the repository to MechUpp.

**Decision:**
1. Product name in prose, Dart UI strings, titles, and logs is **MechUpp** (`mechupp`, `MECHUPP` where appropriate).
2. Android `namespace` and `applicationId` become `com.mechupp.app`.
3. iOS and macOS bundle identifiers become `com.mechupp.app` and product names become `mechupp_app`.
4. Environment variable prefix in FastAPI backend becomes `MECHUPP_` (e.g. `MECHUPP_APP_ENV`).
5. Firebase project ID for emulators becomes `demo-mechupp`.
6. Historical quotes / audit text in `docs/prd/03-frontend-audit.md` stay unchanged.

**Consequences:** Breaking change for local development `.env` files (rename `MECHANICA_` prefixes to `MECHUPP_`).
