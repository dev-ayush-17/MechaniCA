# M08 — Live tracking

## 1. Goal

Show the mechanic on a map with distance, ETA, and a stale state. FR-TRK-001 through FR-TRK-007, including the tracking-link endpoint. Emergency-contact picking is M14. ADR-007.

## 2. Prerequisites

M07 merged.

## 3. Scope

In: RTDB location adapter, gate document maintained by the API, Maps adapter fake plus Google adapter behind config, duty cycle, jump filter, share token endpoint, customer tracking screen replaces the fake timeline, mechanic foreground disclosure copy.

Out: turn-by-turn inside our app (opening Google Maps directions is enough), Hindi, emergency contact address book.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `features/tracking/live_tracking_screen.dart` | Rewrite behavior. Keep the page's job summary if it still makes sense | Widget test: stale label when the point is old. Fake map does not need a golden |
| Emergency tracking | Use the same tracking screen | Route still opens |

## 5. Tasks

1. `test(location): drop a 5 km jump and mark stale at 60 seconds`.
2. `feat(api): booking gate and tracking token`.
3. `feat(location): publish and subscribe through the port`.
4. `refactor(tracking): replace the simulated timeline with the map states`.
5. `feat(maps): route summary with a 30 second cache`.

## 6. Ports

`LocationTrackingService`, `MapsService`. Fakes first.

## 7. Files

`features/tracking/`, `firebase` RTDB rules, `adapters/google_maps`, `adapters/rtdb`.

## 8. Branch and commits

Branch: `feat/m08-tracking`.

## 9. Tests

- `stale_after_60_seconds`
- `jump_over_2km_dropped`
- `token_hides_phone_and_price`
- `token_dies_when_paid`
- `rules_allow_own_location_write`
- `rules_deny_other_party_location_write`

## 10. Acceptance and manual check

- Given `enRoute` and a fresh point, when the customer opens tracking, then they see distance and ETA text even if the map tiles fail.
- Given a point older than a minute, when the screen renders, then the label is "Last seen…".
- Given a share token, when you open the public JSON, then there is no phone and no total.

Manual: two emulator auth users, move the mechanic point with a test helper, watch the customer screen. Open the public URL.

## 11. Definition of done

- [ ] Fake timeline is gone.
- [ ] Rules tests pass.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

Maps keys may be missing. The milestone is done when the fake map and the real adapter both exist and the UI works on the fake. Do not put a key in git to "finish."

## 13. Execution prompt

```
You are implementing MechaniCA milestone M08 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M08-tracking.md. Do not commit API keys. Branch feat/m08-tracking. Update docs/AGENT_PROGRESS.md and open a PR.
```
