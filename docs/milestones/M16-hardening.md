# M16 — Hardening

## 1. Goal

Make the MVP releasable to a staging soak. Accessibility, Hindi for the critical flows, cost guards, security checklist, and a release note. NFR-A11Y, NFR-I18N-002, NFR-BAT, and the launch items in chapters 16 and 21.

## 2. Prerequisites

M14 and M15 merged.

## 3. Scope

In: contrast check and token tweak if body text fails AA. Semantics labels on icon buttons in booking, tracking, payment, and SOS. Hindi ARB for those flows. Rate limits verified. Secret scan in CI (a simple grep for private keys is enough). Staging config documented. Application id called out as still `com.example` until the owner changes it. Privacy policy placeholder URL in settings. Age checkbox on onboarding. Load notes: document how to run a small k6 or locust script against `/health` and quote, not a full city simulation. Delete any demo OTP hint from release builds if M02 left one.

Out: production deploy, store submission, a lawyer's sign-off, new features, Play Integrity enforcement (backlog).

## 4. Existing code

Whatever still fails the NFR list. Do not redesign. Fix contrast, labels, and strings. Fuel and membership stay.

## 5. Tasks

1. `test(a11y): semantics on the pay button and the SOS control`.
2. `feat(l10n): Hindi strings for booking, tracking, payment, and SOS`.
3. `ci: reject probable secrets`.
4. `docs: staging checklist and rollback steps`.
5. `fix: any rule or rate-limit gap found while reading chapter 16 against the code`. File extra gaps as issues rather than expanding into a new product area.

## 6. Ports

None new. Crash reporting may be a `Logger` adapter if it stays a few lines. If it needs a vendor SDK, put it in an adapter and default it off. One-line reason required.

## 7. Files

`lib/l10n/app_hi.arb`, `docs/RELEASE_CHECKLIST.md` created here, CI workflow tweak.

## 8. Branch and commits

Branch: `chore/m16-hardening`. Split fix commits from the Hindi commit.

## 9. Tests

- Semantics tests named above.
- `hi` locale loads the booking confirm button without a missing-translation exception.
- Secret scan fails on a fixture.

## 10. Acceptance and manual check

- Given Hindi selected in the OS, when you open booking, then the primary buttons are Hindi.
- Given English, when you open the same screen, then copy is unchanged from the spec.
- Given a 1.6 text scale, when the price step shows, then the total is still readable.
- Given the release checklist, when you read it, then it tells the owner not to ship `com.example` and not to ship with sandbox payment keys.

Manual: toggle the OS language and the text scale. Run the secret scan. Read the checklist out loud once.

## 11. Definition of done

- [ ] Checklist committed.
- [ ] No new feature scope.
- [ ] Progress file says the MVP spec is implemented and lists owner-only launch steps.
- [ ] PR opened.

## 12. Risks and rollback

Hindi strings can overflow buttons. Allow an extra line of wrap. Do not shrink the font below the accessibility floor. Revert a string commit if a button clips. Do not "fix" overflow by removing the semantics.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M16 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, docs/prd/06-non-functional-requirements.md, and docs/milestones/M16-hardening.md. Do not deploy production. Do not add features. Branch chore/m16-hardening. Update docs/AGENT_PROGRESS.md and open a PR.
```
