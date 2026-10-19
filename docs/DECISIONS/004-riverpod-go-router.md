# ADR-004 — Keep Riverpod and go_router

**Status:** accepted. **Date:** 2026-10-19.

The demo already uses Riverpod 2 and go_router 13 for real screens, not as unused dependencies.

**Decision:** Keep both. Split `app_providers.dart` per feature over time. Do not add get_it, Bloc, or GetX.

**Why this and not the alternatives:** The state layer is one of the few solid parts of the demo (audit score 7/10). Replacing it would be churn. get_it would be a second composition root next to Riverpod.

**Consequences:** Constructor-injected ports are provided by Riverpod. That file is the composition root. Tests override providers instead of a service locator.
