# M15 — Admin and analytics

## 1. Goal

Staff can verify mechanics, inspect orders, manage coupons, resolve disputes, and read revenue. FR-ADM-001 through FR-ADM-009. Analytics events from [chapter 18](../prd/18-analytics.md) go through `AnalyticsService` (log adapter).

## 2. Prerequisites

M09 and M13 merged so disputes and notifications have something to show. M04's approve API should already exist. This milestone adds the web UI and any missing admin routes.

## 3. Scope

In: `main_admin.dart` Flutter web, width gate at 1024 px. Screens: users, verification queue, orders, revenue, coupons, disputes, audit viewer. RBAC on every route. Dispute open from the customer app. Log analytics adapter and the server events for booking and payment. Support can note and cannot refund. Admin can refund by calling the M10 endpoint.

Out: a charting product, ad networks, phone layout for admin, bank payout.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| Support FAQ | Leave it | Route still opens |
| Customer booking details | Add "Report a problem" when status allows dispute | Widget test shows it only after `arrived` |

## 5. Tasks

1. `test(admin): support cannot refund, admin can, both are audited`.
2. `feat(api): disputes and admin lists`.
3. `feat(admin): web shell and the queues`.
4. `feat(analytics): log adapter and server events`.
5. `feat(booking): customer can open a dispute`.

## 6. Ports

`DisputeRepository`, `AnalyticsService`, `AuditLog` (already in M04).

## 7. Files

`app/lib/features/admin/`, `main_admin.dart`, `api/v1/admin/`. Reuse tokens. Do not invent a second color system.

## 8. Branch and commits

Branch: `feat/m15-admin`. API before the web UI.

## 9. Tests

- `support_cannot_resolve_with_refund`
- `suspend_blocks_booking_create`
- `coupon_with_redemptions_cannot_be_edited`
- `analytics_drops_phone_property`
- `dispute_second_open_conflicts`

## 10. Acceptance and manual check

- Given a 900 px window, when admin loads, then the large-screen message shows.
- Given an admin, when they approve a mechanic, then the audit list shows the action.
- Given support, when they try to refund, then the API returns 403.
- Given a customer after arrival, when they open a dispute, then it appears in the queue.

Manual: run the admin entrypoint on Chrome, approve, create a coupon, open a dispute from the customer app, resolve it without a real refund if the payment was fake.

## 11. Definition of done

- [ ] RBAC tested, not only hidden buttons.
- [ ] Revenue reads payments, not estimates.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

Flutter web can surface plugin issues (maps, camera). Do not import those plugins into the admin target. Rollback is a compile flag that excludes them, not a rewrite.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M15 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M15-admin.md. Admin is Flutter web in the same package. Branch feat/m15-admin. Update docs/AGENT_PROGRESS.md and open a PR.
```
