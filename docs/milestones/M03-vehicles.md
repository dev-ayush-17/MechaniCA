# M03 — Vehicles

## 1. Goal

The proving slice: a vehicle is created on the phone, stored by FastAPI in Firestore, cached in Drift, and editable offline. FR-VEH-001, 002, 003, 004, 006. Health (005) waits for M14.

## 2. Prerequisites

M02 merged.

## 3. Scope

In: `Vehicle` domain type with `two_wheeler` and `four_wheeler`. Indian plate validation. List, create, edit, delete, set primary. Drift cache and sync queue for vehicle writes only. Emulator rules: owner can read, nobody can client-write. Seed two vehicles with valid plates. Map the existing My Bikes screens onto this API. Copy can still say "bike".

Out: booking create, service history from real bookings (show an empty history state), photos upload, four-wheeler-only new screens beyond the type field.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `features/bikes/my_bikes_screen.dart` | Refactor. Split add and details into real files if you touch them | Widget test: empty list copy, and a list with one vehicle shows the registration |
| `models/bike_model.dart` | Replace with Freezed `Vehicle` in a refactor commit. Keep a mapper from old mock if any screen still needs it | Model test for plate validation |
| `repositories/bike_repository.dart` | Fake adapter implements `VehicleRepository` | Contract test shared examples |
| Mock bikes with `BR80Y 024` | Stop using them as valid examples | Test rejects that string |

## 5. Tasks

1. Tests for plate validation and the empty state.
2. `refactor(vehicles): introduce Vehicle and split bike screens` without changing layout.
3. `feat(api): add vehicle endpoints and rules tests`.
4. `feat(app): add Drift cache and the vehicle sync queue`.
5. `feat(vehicles): point the bikes UI at the API with offline queue`.

## 6. Ports

`VehicleRepository`. Fake and Firestore adapters. Drift is a local adapter behind the same port or a small `VehicleCache` used by the repository implementation. Do not invent a second public port if the repository can hide the cache.

## 7. Files

`features/vehicles/` may be the new folder while routes stay `/bikes`. Say so in the PR. Backend `api/v1/vehicles.py`. Drift database in `data/local`.

## 8. Branch and commits

Branch: `feat/m03-vehicles`. Refactor commit before the API commit.

## 9. Tests

- `rejects_mock_plate_br80y024`
- `accepts_br01ab1234`
- `second_primary_unsets_the_first`
- `offline_edit_queues_and_flushes`
- `rules_deny_client_vehicle_write`
- `queue_has_no_booking_create_kind`

## 10. Acceptance and manual check

- Given a signed-in user, when they add a bike with a valid plate, then it survives restart with the emulator running.
- Given airplane mode, when they edit the color, then they see "Saved on this phone" and the change reaches the server after the network returns.
- Given an invalid plate, when they save, then they see "Enter a valid registration number."

Manual: add a vehicle, kill the app, reopen, see it. Turn networking off, edit, turn it on, confirm the API returns the edit.

## 11. Definition of done

- [ ] Slice works on the emulator end to end.
- [ ] Fake adapter still lets tests run with no emulator.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

Drift codegen can dominate the diff. Keep generated files in the commit and out of the "hand-written line" worry, but do not also rewrite booking. Rollback the UI binding to the fake repository if the emulator blocks the session. Do not leave the screen crashing.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M03 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, docs/prd/09-domain-and-data-model.md, and docs/milestones/M03-vehicles.md. This is the Flutter to FastAPI to Firestore slice. Do not implement booking. Branch feat/m03-vehicles. Update docs/AGENT_PROGRESS.md and open a PR.
```
