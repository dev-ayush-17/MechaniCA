# M04 — Mechanics

## 1. Goal

A mechanic can apply, upload documents, and be approved by an admin endpoint. FR-MEC-001, 002, 003, 004. Earnings numbers wait for M10. Accept/reject waits for M07.

## 2. Prerequisites

M02 merged. M03 is not required, but do not start this if M03's PR is open on the same branch.

## 3. Scope

In: mechanic entrypoint `main_mechanic.dart` with a plain onboarding flow. Application fields from chapter 05. Signed upload URLs. Admin HTTP endpoint to approve or reject, even if the admin UI is M15. A curl or httpx test is enough for the decision. Availability toggle for approved mechanics. Heartbeat endpoint. Audit log append on approve and reject.

Out: dispatch, maps, admin web UI, bank payout, customer booking.

## 4. Existing code

No mechanic screens exist. Do not reshape the customer app except a note in the customer profile if a mechanic account opens it (FR-AUTH role message). That message is in scope.

## 5. Tasks

1. `feat(api): add mechanic application, documents, and verification`.
2. `feat(api): record verification in the audit log`.
3. `feat(app): add the mechanic onboarding flow` using existing buttons and text fields.
4. `feat(mechanic): toggle availability when verified`.
5. `test(rules): owner reads documents, clients cannot set verified`.

## 6. Ports

`MechanicRepository`, `FileStorage`, `AuditLog`. Fakes first. Firebase Storage and Firestore second.

## 7. Files

`app/lib/features/mechanic_onboarding/`, `main_mechanic.dart`, `backend/app/api/v1/mechanic.py`, `backend/app/api/v1/admin_verification.py`.

## 8. Branch and commits

Branch: `feat/m04-mechanics`. One commit per task. The admin endpoint is a `feat(api)` commit, not a hidden part of the Flutter commit.

## 9. Tests

- `unverified_mechanic_cannot_go_online`
- `approve_sets_verified_and_audit`
- `reject_requires_a_reason`
- `client_cannot_write_verified`
- `signed_upload_rejects_parent_directory`

## 10. Acceptance and manual check

- Given a mechanic bootstrap, when documents are not approved, then the availability switch is disabled.
- Given the admin approve call, when the mechanic refreshes the token, then the switch enables.
- Given a customer token in the mechanic app, when it opens, then it explains the phone is a customer account.

Manual: run the mechanic entrypoint against the emulator, submit, approve with the test client, toggle online.

## 11. Definition of done

- [ ] Verification cannot be self-served.
- [ ] Documents are not world-readable.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

File upload on the emulator is the likely time sink. A fake storage adapter must work in tests even if Storage emulator setup slips. Do not skip the rules test.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M04 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M04-mechanics.md. Admin UI is out of scope. An API to approve is in scope. Branch feat/m04-mechanics. Update docs/AGENT_PROGRESS.md and open a PR.
```
