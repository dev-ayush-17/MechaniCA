# M12 — Chat and masked calling

## 1. Goal

The customer and the assigned mechanic can chat for the life of the booking. Calling is a port. FR-COM-001 through FR-COM-004.

## 2. Prerequisites

M06 merged. The thread becomes useful after M07 assigns a mechanic. Do not block on M08.

## 3. Scope

In: messages API, Firestore read for the parties, rate limit, offline text queue, image upload using the M04 storage port, chat UI on the booking. `TelephonyPort` and a fake that returns a test number. `masked_call_enabled` default off in prod flavor and on in dev. When off, the button is hidden. When on, the dialer opens the masked number. Never the raw number.

Out: the support FAQ chat. Leave `features/support` mock behavior alone. Video. A vendor contract.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `features/support/support_screen.dart` chat | Do not turn this into mechanic chat | Existing support route still opens |
| New UI | Build `features/job_chat/` | Widget test: empty thread copy and a failed message retry |

## 5. Tasks

1. `test(chat): lifecycle window and rate limit`.
2. `feat(api): messages and rules that deny client writes`.
3. `feat(chat): thread UI and offline queue`.
4. `feat(calling): masked number port and flag`.

## 6. Ports

`ChatService`, `TelephonyPort`, `FileStorage`.

## 7. Files

`features/job_chat/`, `api/v1/messages.py`. Add `url_launcher` if it was removed, reason: "open the dialer for a masked number."

## 8. Branch and commits

Branch: `feat/m12-chat`.

## 9. Tests

- `message_after_24h_is_rejected`
- `twenty_first_message_is_rate_limited`
- `offline_text_queues`
- `call_hidden_when_flag_off`
- `adapter_does_not_return_the_user_phone`

## 10. Acceptance and manual check

- Given an assigned booking, when one party sends text, then the other sees it after refresh or the listener.
- Given a terminal booking older than 24 hours, when they send, then the composer is read-only.
- Given the flag off, when the screen opens, then there is no Call button.

Manual: two users, send a message, see it. Confirm support chat still shows the old FAQ.

## 11. Definition of done

- [ ] Raw phone numbers are not in the chat payload or the call adapter response.
- [ ] Tests pass.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

Listeners are optional. Polling every few seconds is acceptable if the listener slips, as long as the API remains the writer. Do not switch to client writes to "make chat easy."

## 13. Execution prompt

```
You are implementing MechaniCA milestone M12 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M12-chat-calling.md. Do not expose raw phone numbers. Leave the support FAQ screen on its mock path. Branch feat/m12-chat. Update docs/AGENT_PROGRESS.md and open a PR.
```
