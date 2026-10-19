# M09 — Notifications

## 1. Goal

Send the matrix in [chapter 17](../prd/17-notifications.md) through a port. In-app list uses the existing screen. FR-NOT-001, 002, 004. SMS stays behind a flag, default off (FR-NOT-003).

## 2. Prerequisites

M06 merged. Events that do not exist yet (payment, verification) get a sender function and a test that calls it. M04 and M10 call the same function when those milestones already landed. If this milestone runs before M10, payment templates are still unit-tested with a direct call.

## 3. Scope

In: `NotificationSender`, FCM adapter, recording fake, device token endpoint, notification documents, read and delete endpoints, deep links, the current notifications screen bound to real data. Permission screen calls the OS prompt once.

Out: marketing campaigns, SMS vendor contract, email.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `features/home/notifications_screen.dart` | Refactor onto the repository | Widget test: empty copy "No notifications yet." |
| Notification permission screen | Call the real API once. Keep the layout | Test the denied banner copy exists on home when the flag is set |

## 5. Tasks

1. `test(notifications): matrix rows have a template`.
2. `feat(api): write in-app notifications and read endpoints`.
3. `feat(notify): FCM adapter and device tokens`.
4. `refactor(notifications): bind the existing list`.
5. `feat(booking): emit assigned, arrived, and cancelled` from the use cases that already exist.

## 6. Ports

`NotificationSender`. Channels inside the message, not three ports.

## 7. Files

`features/notifications/`, `backend/app/application/notify.py`, `adapters/fcm.py`.

## 8. Branch and commits

Branch: `feat/m09-notifications`.

## 9. Tests

- Every template id in chapter 17 has a non-empty title.
- `failed_push_does_not_roll_back_booking`
- `read_endpoint_only_owner`
- `sms_not_called_when_flag_off`

## 10. Acceptance and manual check

- Given a confirmed booking that becomes assigned, when the customer opens the bell, then "Mechanic assigned" is there.
- Given another user, when they call read on that id, then 404 or 403.
- Given push permission denied, when home opens, then the banner copy from chapter 17 shows once, not a modal loop.

Manual: trigger an assignment with the emulator and a debug FCM token if you have one. If you do not, the recording fake and the in-app row are enough. Say that in the PR.

## 11. Definition of done

- [ ] Matrix covered by a test.
- [ ] Client cannot write notification docs.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

FCM without a real project only tests the fake. Do not stall the milestone on a Firebase project. Rollback is the recording adapter.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M09 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, docs/prd/17-notifications.md, and docs/milestones/M09-notifications.md. Branch feat/m09-notifications. Update docs/AGENT_PROGRESS.md and open a PR.
```
