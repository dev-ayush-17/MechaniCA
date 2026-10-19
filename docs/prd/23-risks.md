# 23 — Risk register

Scores are Low, Medium, or High. Review this table at the start of M16 and after any SEV-1.

| ID | Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| R1 | Workshop flow in the demo is mistaken for the product and gets "preserved" into the API | Medium | High | ADR-002. M06 replaces the enum. Audit chapter says so in plain language |
| R2 | Client writes status because rules were left open to "move faster" | Medium | High | Emulator tests deny writes. PR review. `security.mdc` |
| R3 | Webhook marks bookings paid on a bad or mismatched event | Low | High | Verify signature. Amount check. Alert on mismatch. Replay test |
| R4 | Cashfree or Maps keys leak in git | Medium | High | Ignore files, secret scan in M16, no keys in this phase |
| R5 | RTDB location writes cost more than expected | Medium | Medium | Duty cycle, overwrite one node, metric and alert |
| R6 | Team swaps Firebase for Supabase mid-build and rewrites UI | Medium | High | Ports and the Postgres mapping. UI must not import Firestore |
| R7 | Auth vendor decision stalls M02 | Medium | Medium | Fake adapter and Firebase default. Do not wait |
| R8 | Masked-call vendor is not chosen by M12 | High | Medium | Chat still ships. Call stays behind a flag. Raw numbers are not a fallback |
| R9 | God-file refactor breaks the demo | Medium | Medium | Characterization tests first. One feature per milestone. `main` stays runnable |
| R10 | `develop` (MechUpp rename) is merged blindly and fights this spec | Medium | Medium | Do not merge `develop` as part of M00. Cherry-pick visual fixes only with a reason |
| R11 | GST or cancel-fee assumption is wrong | Medium | Low before launch | Config, not constants in widgets |
| R12 | Single mechanic sequential offer is too slow for SOS | Medium | Medium | 20 second TTL and wider radius. Fan-out is a Phase 2 change with its own state design |
| R13 | Admin Flutter web is painful for tables | Low | Medium | ADR allows a later web app behind the same API |
| R14 | No legal review before launch | Medium | High | M16 checklist. Not a substitute for a lawyer |
| R15 | Owner's example application id ships to production | Medium | Medium | M16 release checklist |
| R16 | Duplicate mock registration numbers become validation examples | Low | Medium | Seed script uses valid plates. Audit calls out `BR80Y 024` |
| R17 | Agents expand a milestone "while they are here" | High | Medium | Milestone file is the scope. Discoveries become ADRs or PRD edits, not silent features |
| R18 | Payment succeeds and the app shows failure, user pays twice | Medium | High | Idempotency key. UI stays on "waiting" until the server says `paid` |
| R19 | Hindi launch promised verbally while spec says M16 | Medium | Medium | Written assumption. Moving Hindi earlier is a scope change to M16's predecessor, not a drive-by |
| R20 | Emulator-only tests pass and prod rules were never deployed | Medium | High | M16 includes a staging rules deploy, which is an owner action, plus a checklist |
