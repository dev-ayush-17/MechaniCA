# M07 — Dispatch

## 1. Goal

Offer a confirmed job to one mechanic at a time, expire the offer, and reassign twice. FR-BOOK-008, FR-MEC-005, the mechanic half of FR-MEC-006, SOS timings, and the extra-work timeout from FR-BOOK-009. [Chapter 14](../prd/14-dispatch.md). ADR-008 and ADR-013.

## 2. Prerequisites

M06 merged.

## 3. Scope

In: `DispatchService`, `JobScheduler` fake plus a Cloud Tasks adapter that is not called in dev. Offer accept and reject. Ranking function. Sweeper use case for expired offers. Mechanic offer screen. Status buttons for Start trip, Arrived, Start service. Complete stays blocked until M13 if parts are required. Jobs with no part lines can complete.

Out: Google Map, FCM (write the notification port call behind a fake that records the send), payments.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| Emergency and tracking screens | Do not rewrite the map yet. Tracking may still be the old animation until M08. Status changes go through the API | Test the offer screen in isolation |
| Customer "finding a mechanic" copy | Add to booking details | Widget test for the failed copy |

## 5. Tasks

1. `test(dispatch): ranking, timeout, and double accept`.
2. `feat(api): create offers and the timeout use case`.
3. `feat(scheduler): fake job scheduler and the sweep`.
4. `feat(mechanic): offer accept and reject screen`.
5. `feat(mechanic): legal status buttons`.
6. `feat(booking): extra-work ten minute timeout`.

## 6. Ports

`DispatchService`, `JobScheduler`, `MechanicRepository.findOnlineNear`. `NotificationSender` can be a recording fake. The real FCM adapter is M09.

## 7. Files

`backend/app/domain/dispatch.py`, `api/v1/offers.py`, `api/v1/internal/jobs.py`, `features/mechanic_jobs/`.

## 8. Branch and commits

Branch: `feat/m07-dispatch`.

## 9. Tests

- `dispatch_second_accept_loses`
- `dispatch_third_miss_fails`
- `sos_timeout_is_20_seconds`
- `mechanic_with_active_job_is_skipped`
- `expired_offer_is_idempotent`
- `outside_service_area_excluded`

## 10. Acceptance and manual check

- Given two online mechanics, when a booking is confirmed, then only the higher score gets an open offer.
- Given no accept, when the fake clock advances, then the second mechanic is offered.
- Given three misses, when the last expires, then the customer booking is `failed` and the copy matches chapter 14.

Manual: seed two mechanics, go online, create a booking, accept on one device or one emulator plus an API call, move to `enRoute`.

## 11. Definition of done

- [ ] Sequential offers only.
- [ ] Handlers are safe to run twice.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

Cloud Tasks is easy to overbuild. Dev must use the fake scheduler. If the adapter is unfinished, ship the fake and a documented interface. Do not block the milestone on a GCP project.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M07 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, docs/prd/14-dispatch.md, and docs/milestones/M07-dispatch.md. Do not add map tiles or real push. Branch feat/m07-dispatch. Update docs/AGENT_PROGRESS.md and open a PR.
```
