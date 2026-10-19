# 24 — Out of scope and Phase 2

## Won't in MVP (screens may already exist)

| Item | What to do with the current UI |
| --- | --- |
| Pickup and workshop fulfillment | Do not extend `pickedUp` / `inWorkshop`. Leave the widgets until M06 replaces the flow. No new pickup features |
| Fuel tracker | Keep the route working on mock data |
| Membership plans and purchase | Keep the mock screen. No payment hookup |
| Refer and earn payouts | Keep the mock screen |
| Document vault (RC, insurance, PUC files) | Keep the placeholder |
| Loyalty earn and burn | Read-only display if a number exists. No API |
| Mechanic bank payout | Earnings are recorded only. The screen says payout is not live |
| Email/password accounts | No |
| Phone number change | No |
| Customer-to-mechanic role switching | No |
| Video chat or video uploads | No |
| Multi-city operations console | One config polygon |
| Hindi | M16, not Phase 2, but not MVP launch-blocking |
| iPad and tablet layouts | Phones and admin desktop widths |
| Self-serve account deletion | Scripted by an admin in M16. In-app flow is Phase 2 |
| Fan-out dispatch to many mechanics at once | Sequential offers only |
| Dynamic pricing and surge | Catalog price plus vehicle-type multiplier only |
| Spare-parts marketplace | Parts are line items, not a catalog shop |
| Insurance claims integration | No |
| MechaniCA-branded replacement parts | No |

## Phase 2 backlog (ordered only as a suggestion)

1. Workshop / pickup as a `serviceMode` on the same booking machine, if the business still wants it.
2. Bank payouts to mechanics (`PayoutService`).
3. Hindi completion beyond the M16 set, and any other language.
4. Membership subscriptions that grant a discount, using the existing screens.
5. Referral rewards with a ledger reason `referral`, not a new wallet.
6. Fuel logs and a richer vehicle health model from real inspection data.
7. Document vault with expiry reminders.
8. In-app account deletion and phone change.
9. Fan-out offers, with a designed race, if sequential SOS is too slow in the field.
10. A dedicated admin web framework, only if Flutter web blocks the support team.
11. Play Integrity / App Check enforcement.
12. OpenTelemetry traces.

## Explicitly rejected for now

- Cloud Functions as a second backend.
- The client writing booking status "and the API double-checks later."
- Microservices per feature.
- Rewriting the demo in another UI toolkit.
- Merging the MechUpp rename without a product decision. The default name remains MechaniCA.
