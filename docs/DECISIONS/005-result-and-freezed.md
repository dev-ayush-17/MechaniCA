# ADR-005 — Sealed Result and Freezed

**Status:** accepted. **Date:** 2026-10-19.

The demo uses hand-written models. `NotificationModel.isRead` is mutable. Errors are often swallowed.

**Decision:** Expected failures use a small sealed `Result<T>` in `core/`. No fpdart. Models become Freezed with `json_serializable` in the milestone that touches them.

**Why this and not the alternatives:** fpdart is a reasonable library, and we would use one type from it. Dart 3 already expresses that type. Freezed is justified because we keep getting `copyWith` and JSON wrong by hand.

**Consequences:** Generated files are excluded from the 1,500-line milestone budget. Do not Freezed every model in M01. Convert a model when its feature milestone edits it. M01 may convert one sample if the toolchain needs a proof.
