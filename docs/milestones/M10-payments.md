# M10 — Payments

## 1. Goal

Collect the approved total by Cashfree, cash, or wallet, with coupons and refunds. FR-PAY-002 through FR-PAY-010, FR-USR-004, FR-USR-005, FR-MEC-007. [Chapter 15](../prd/15-payments.md).

## 2. Prerequisites

M06 merged. M09 should be merged if you want real payment pushes. If it is not, call the recording notifier.

## 3. Scope

In: payment create, webhook, reconciler use case, wallet ledger, top-up, cash marks, coupon validate and redeem, cancel-fee debt, earnings list from paid shares, wallet and offers screens bound to the API. Fake gateway by default.

Out: invoice PDF (M11), live Cashfree keys in git, card fields in our UI.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `wallet_screen.dart`, `add_money` | Refactor to the ledger | Widget test: empty "No transactions yet." |
| `offers_screen.dart` | Refactor to server coupons | Test invalid code message |
| Booking pay step | Start payment and show "Waiting for confirmation" | Test that a fake SDK success string does not show "Paid" until the server says so |
| Coupon checks inside the wizard | Delete them | Pricing test still passes |

## 5. Tasks

1. `test(payments): signature, replay, wallet, coupon`.
2. `feat(api): payments, wallet, coupons`.
3. `feat(payments): cash confirm flow`.
4. `feat(app): wire wallet, offers, and the pay step`.
5. `feat(mechanic): recorded earnings list`.
6. `feat(payments): reconcile pending rows`.

## 6. Ports

`PaymentGateway`, `PaymentRepository`, `WalletService`, `CouponService`. Fake gateway signs with a test secret.

## 7. Files

`features/wallet`, `features/offers`, `features/payments`, `backend/app/api/v1/payments.py`. No PAN fields anywhere. Grep the diff for `cvv` and `cardNumber`.

## 8. Branch and commits

Branch: `feat/m10-payments`. Tests first. UI in its own commit.

## 9. Tests

- `webhook_bad_signature_does_not_pay`
- `webhook_replay_is_noop`
- `webhook_amount_mismatch_does_not_pay`
- `wallet_debit_cannot_go_negative`
- `coupon_redeem_once`
- `cash_requires_both_marks`
- `client_sdk_success_is_not_paid`

## 10. Acceptance and manual check

- Given a completed booking, when the fake webhook fires, then status is `paid` once.
- Given a bad signature, when the webhook hits, then status stays `pending`.
- Given cash, when only the mechanic marks it, then it is not paid.
- Given a coupon that expired, when paying, then the client shows the server message and does not charge.

Manual: complete a no-parts job, pay with the fake gateway helper, see the wallet unchanged for UPI and reduced for wallet. Open earnings as the mechanic.

## 11. Definition of done

- [ ] Phone cannot mark paid.
- [ ] Tests above pass.
- [ ] Offers and wallet no longer use hardcoded balances.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

This is the largest milestone. If the diff exceeds about 1,500 hand-written lines, split before continuing: API and tests first, UI second, as two PRs that still match this file's tasks. Do not add invoices to "finish the flow."

## 13. Execution prompt

```
You are implementing MechaniCA milestone M10 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, docs/prd/15-payments.md, and docs/milestones/M10-payments.md. Never handle raw card data. Never mark paid from the client SDK. Branch feat/m10-payments. Update docs/AGENT_PROGRESS.md and open a PR.
```
