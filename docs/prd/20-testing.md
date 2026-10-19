# 20 — Testing

## Pyramid

| Layer | What | Where | Runs |
| --- | --- | --- | --- |
| Unit | Domain, pricing, state machine, mappers | `app/test`, `backend/tests/unit` | Every PR |
| Contract | Each port's fake and real adapter against the same examples | `backend/tests/contract`, Dart equivalents | Every PR for fakes. Real adapters in nightly if they need keys |
| Emulator | Rules, Firestore writes, token verify | `backend/tests/emulator`, `firebase/tests` | PR once emulators are in CI (M00 wires the job, later milestones add cases) |
| Widget | Screen states with fake notifiers | `app/test` | PR when UI changes |
| Integration | One flow on the emulator | `app/integration_test` | Nightly, and the milestone that owns the flow |
| E2E | Cashfree sandbox, real maps | Manual script in the milestone, automated later | Staging before release |

Do not aim for a percentage coverage gate on day one. Do aim for the critical cases below to exist by the milestone that introduces the behavior. A milestone is not done if its named tests are missing.

## Critical cases

| Test name | Asserts |
| --- | --- |
| `booking_state_rejects_cancel_after_arrived` | `arrived` → `cancelled` is `Conflict` |
| `booking_create_is_idempotent` | Same key returns the same id. Different body conflicts |
| `pricing_gst_splits_even_paise` | 18% GST, CGST and SGST differ by at most 1 paise, sum matches |
| `coupon_redeem_once` | Second redeem on the same booking is a no-op success or a conflict, not a double discount |
| `dispatch_second_accept_loses` | One booking, two accepts, one `offer_gone` |
| `dispatch_third_miss_fails` | Three expired offers, status `failed` |
| `webhook_bad_signature_does_not_pay` | Payment stays `pending` |
| `webhook_replay_is_noop` | Two deliveries, one `paid` transition |
| `wallet_debit_cannot_go_negative` | `insufficient_wallet` |
| `rules_deny_client_booking_write` | Emulator test as a signed-in user |
| `rules_allow_own_location_write` | Only the assigned mechanic, only while open |
| `parts_complete_blocked_without_photos` | `inService` → `completed` fails |
| `offline_queue_does_not_create_bookings` | Queue kinds do not include booking create |

## Flutter

- Characterization test before refactoring a screen: pump the widget with a fake notifier and assert the title and primary button the user sees.
- Golden tests are optional and only for shared widgets whose layout is easy to break (`AppButton`, price row). Do not golden the whole home screen in M01.
- The broken `MyApp` test is replaced in M01 with a test that pumps `MechaniCAApp` and finds the splash wordmark.

## FastAPI

- pytest, `httpx.AsyncClient`, dependency overrides for ports.
- One test per transition in the state table, generated from the table if that stays readable, otherwise written out. Readable beats clever.
- ruff and mypy run in CI. mypy is strict on `domain` and `application`. Adapters can start untyped at the SDK boundary and narrow over time. Do not `# type: ignore` a payment module.

## Fixtures

Dev seed script (M00 skeleton, filled per milestone) creates the demo user, two vehicles with **valid** registration numbers, the five catalog rows, and one coupon. It does not copy `BR80Y 024`.

## Definition of a good test

It fails if the money, the status, or the permission is wrong. It does not fail because a label gained a period. Widget tests assert role and visible text that the requirement named, not the entire tree.
