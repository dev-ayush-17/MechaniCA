# M14 — Dashboard, history, and profile

## 1. Goal

Home, history, profile, addresses, emergency contacts, repeat booking, and an honest health label. FR-USR-001, 002, 003, 006, 007, 009 and FR-VEH-005. The share button's recipient list uses emergency contacts. The token API already exists from M08.

## 2. Prerequisites

M08 and M11 merged, so home can show a real active booking and a real invoice link. M03 for vehicles.

## 3. Scope

In: bind home cards to real bookings and the primary vehicle. History tabs. Profile edit and addresses with lat/lng. Emergency contacts. Book again. Health copy from the last service date. Split `home_screen.dart` if you are touching it, after a characterization test.

Out: loyalty earn/burn (FR-USR-008). Fuel, membership, referral, documents backends. A visual redesign of home.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `home_screen.dart` | Refactor bindings. Keep sections | Widget test: no active booking shows "Book a service" |
| `history_screen.dart` | Refactor onto booking query | Empty copy test |
| `profile_screen.dart` | Refactor forms | Save name test |
| `health_score_screen.dart` | Replace the constant 85 | Copy mentions last service |

## 5. Tasks

1. Characterization tests for home empty state and history empty state.
2. `refactor(home): bind cards to repositories`.
3. `feat(profile): addresses and emergency contacts`.
4. `feat(history): repeat service prefill`.
5. `feat(health): placeholder score from last service`.
6. `feat(tracking): share sheet includes emergency contacts`.

## 6. Ports

No new port. `UserRepository` gains address and contact methods if they are not separate. Separate `AddressRepository` only if `UserRepository` is already hard to read. Prefer methods on the existing repository until the third storage concern.

## 7. Files

`features/home`, `features/history`, `features/profile`, `api/v1/addresses.py`, `api/v1/contacts.py`.

## 8. Branch and commits

Branch: `feat/m14-dashboard`. Refactor commits stay separate from the repeat-service feature.

## 9. Tests

- `health_good_within_90_days`
- `repeat_recalculates_price`
- `address_requires_pincode`
- `max_three_emergency_contacts`
- `home_does_not_invent_a_wallet_total`

## 10. Acceptance and manual check

- Given no bookings, when home opens, then the empty booking card is the real empty state, not a mock job.
- Given a paid past job, when you tap Book again, then vehicle and service are filled and the date is empty.
- Given a last service 200 days ago, when health opens, then the label is poor and the explanatory sentence is visible.
- Given an emergency contact, when you share tracking, then that name is offered. The app does not text them by itself.

Manual: walk home, history, profile, health, and the share sheet on an active job.

## 11. Definition of done

- [ ] Mock user `usr_001` is not hardcoded in the screens you touched.
- [ ] Fuel and membership routes still open.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

Home is a 700-line file. Extract sections without changing spacing more than the analyzer requires. If a section breaks, revert that commit only.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M14 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M14-dashboard.md. Do not redesign the home screen. Do not build loyalty or fuel APIs. Branch feat/m14-dashboard. Update docs/AGENT_PROGRESS.md and open a PR.
```
