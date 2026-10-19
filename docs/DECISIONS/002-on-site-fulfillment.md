# ADR-002 — On-site mechanic, not workshop pickup

**Status:** accepted. **Date:** 2026-10-19.

The demo's booking status goes through `pickedUp`, `inWorkshop`, and `outForDelivery`. The product brief is a mechanic who comes to the vehicle.

**Decision:** MVP status is `requested → confirmed → mechanicAssigned → enRoute → arrived → inService → completed → paid`, plus `cancelled`, `failed`, and `disputed`. Workshop mode is Phase 2.

**Why this and not the alternatives:** Keeping the demo's states would build the wrong marketplace. Supporting both modes in MVP doubles dispatch, pricing, and UI before the first city works.

**Consequences:** M06 replaces the enum even though the wizard layout stays. Old status strings are not written to Firestore.
