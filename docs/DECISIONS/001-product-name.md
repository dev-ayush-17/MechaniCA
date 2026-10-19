# ADR-001 — Product name stays MechaniCA (Superseded by ADR-016)

**Status:** superseded by [ADR-016](016-product-name-mechupp.md). **Date:** 2026-10-19.

`main` brands the app MechaniCA. The unmerged `develop` branch renames it to MechUpp.

**Decision:** Specs, copy, and new code say MechaniCA until the owner asks for a rename.

**Why this and not the alternatives:** Shipping the rename now would mix a brand change into every milestone. A rename is application id, titles, and strings. It does not change ports or the booking model.

**Consequences:** Do not merge `develop` only to pick up the rename. Visual fixes on that branch can be cherry-picked later with their own review.
