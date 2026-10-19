# M13 — Parts proof and reviews

## 1. Goal

A part replacement has three photos before the job can complete, and the customer can review the mechanic. FR-MEC-008 and FR-REV-001 through FR-REV-004.

## 2. Prerequisites

M06 merged. Completion already exists in a limited form from M07. This milestone makes parts mandatory when the line says so.

## 3. Scope

In: proof records, compression rules, offline queue, customer gallery using the inspection screen's layout where it fits, review form with up to 3 optional photos (FR-REV-002), aggregate recomputed on the server, hide review action for staff via API.

Out: a new visual design of the inspection screen, video, mechanic reviews of customers.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `features/inspection/digital_inspection_screen.dart` | Refactor into the customer proof view. Keep the before/after structure | Widget test: three photo labels render |
| Complete action | Call the API which enforces photos | `parts_complete_blocked_without_photos` |

## 5. Tasks

1. `test(parts): complete blocked and metadata stored`.
2. `feat(api): proofs and review aggregate`.
3. `feat(mechanic): capture and queue the three photos`.
4. `refactor(inspection): show server proofs to the customer`.
5. `feat(reviews): submit and display`.

## 6. Ports

`ReviewRepository`, `FileStorage`. Proofs can be methods on `BookingRepository` or a small `PartsProofRepository` if the booking port is getting crowded. One extra port is justified here because uploads are a different failure mode. Write that reason in the PR.

## 7. Files

`features/parts_proof/`, `features/reviews/`, `api/v1/reviews.py`. `image_picker` returns if it was removed. Reason: "capture parts photos."

## 8. Branch and commits

Branch: `feat/m13-parts-reviews`.

## 9. Tests

- `parts_complete_blocked_without_photos`
- `proof_path_is_server_chosen`
- `hidden_review_excluded_from_average`
- `one_review_per_booking`
- `phone_number_in_review_is_pending_or_rejected` per chapter 05

## 10. Acceptance and manual check

- Given a part line, when the mechanic has only two photos, then Complete fails.
- Given three uploaded photos, when the customer opens the booking, then they see them.
- Given a 5-star review with no text, when it is saved, then the mechanic average updates after refresh.
- Given a hidden review, when the public list loads, then it is absent and the average excludes it.

Manual: add a part line through the API, upload three images (or the fake storage), complete, review.

## 11. Definition of done

- [ ] Photos are not deletable by the mechanic.
- [ ] Aggregates are not client-writable.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

The inspection screen is large. Reuse it. If the refactor slips, add a new route and leave the old mock route reachable from a debug button rather than deleting the demo path in a broken state. Prefer finishing the new route.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M13 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M13-parts-and-reviews.md. Branch feat/m13-parts-reviews. Update docs/AGENT_PROGRESS.md and open a PR.
```
