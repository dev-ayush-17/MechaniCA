# M06 — Booking core

## 1. Goal

A customer can create one idempotent on-site booking and cancel it under the rules. The server owns the state machine. FR-BOOK-001, 002, 004, 005, 006, 007, and the approval endpoint of FR-BOOK-009. Dispatch assignment is a fake that leaves the job `confirmed`. SOS sets `urgency=sos` but uses normal offer timing until M07.

## 2. Prerequisites

M04 and M05 merged.

## 3. Scope

In: `POST /v1/bookings` with `Idempotency-Key`. Transitions endpoint. Cancel fees as config (do not charge a card yet; record the fee on the booking). Active-booking conflict. Wizard submits to the API. Replace workshop statuses in domain code. Customer cancel UI. Extra-work decision endpoint and a pending line, without the 10 minute Cloud Task (M07). Scheduled window validation.

Out: real mechanic matching, map, payment capture, push.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `booking_flow_screen.dart` | Refactor submit to the API. Keep steps | Widget test: confirm shows an error if offline |
| `booking_model.dart` | Replace status enum in a refactor commit | State machine unit tests |
| `booking_details_screen.dart` | Wire cancel. Keep layout | Test: cancel after a fake `arrived` shows the dispute copy and does not call cancel |
| Emergency screen | Send `urgency=sos` | Test the payload |

## 5. Tasks

1. `test(booking): state table and idempotent create`.
2. `refactor(booking): replace workshop statuses in the model`.
3. `feat(api): create and transition bookings`.
4. `feat(booking): submit the wizard to the API`.
5. `feat(booking): cancel with the fee rules`.
6. `feat(booking): approve or reject an extra line`.

## 6. Ports

`BookingRepository`. Fake and Firestore. Pricing from M05. No `DispatchService` yet. A dev-only flag may set status straight to `confirmed`.

## 7. Files

`backend/app/domain/booking_state.py`, `api/v1/bookings.py`, `features/booking/domain/`. Delete unused workshop enum values once nothing references them.

## 8. Branch and commits

Branch: `feat/m06-booking`. State-machine tests before the refactor of the enum.

## 9. Tests

- `booking_state_rejects_cancel_after_arrived`
- `booking_create_is_idempotent`
- `booking_in_progress_conflict`
- `scheduled_window_too_soon`
- `sos_sets_urgency`
- `enroute_cancel_records_fee`
- `extra_line_reject`

## 10. Acceptance and manual check

- Given a double tap, when the same key is sent, then one booking exists.
- Given airplane mode, when you tap Confirm, then the draft stays and nothing is created later in silence.
- Given `enRoute` in a test fixture, when the customer cancels, then the fee is ₹99 by default.
- Given `arrived`, when they cancel, then they see the support copy.

Manual: create an instant booking on the emulator, see it on the details screen, cancel it while it is still `confirmed`, see the fee as zero.

## 11. Definition of done

- [x] Workshop statuses are gone from domain code.
- [x] Idempotency tested.
- [x] Demo's other tabs still open.
- [x] Progress updated. PR opened.

## 12. Risks and rollback

The enum rename will touch many switches. Do it in one refactor commit and fix the analyzer before the feature commit. If the wizard breaks, revert the UI commit and keep the API.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M06 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, docs/prd/13-state-machines.md, and docs/milestones/M06-booking.md. Do not build real dispatch or payments. Branch feat/m06-booking. Update docs/AGENT_PROGRESS.md and open a PR.
```
