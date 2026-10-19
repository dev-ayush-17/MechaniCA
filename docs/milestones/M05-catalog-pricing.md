# M05 — Catalog and pricing

## 1. Goal

Services come from the server and the estimate is a pure function. FR-BOOK-003 and FR-PAY-001.

## 2. Prerequisites

M03 merged, because the quote depends on vehicle type.

## 3. Scope

In: seed the five services from chapter 05. `POST /v1/quotes` with no side effects. GST split. Four-wheeler labor multiplier 1.5 from config. Coupon parameter accepted but a missing coupon service can return "coupons arrive in M10" only if the code is non-empty. Empty code means no discount. The booking wizard's service and price step reads the quote. Offline catalog cache for 24 hours.

Out: creating a booking, redeeming a coupon, payments.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `features/booking/booking_flow_screen.dart` | Refactor the service and price steps to show server lines. Keep the step order and the visual style | Widget test that a quote with labor 59900 renders `₹599` |
| `models/service_model.dart` and `MockServiceRepository` | Fake catalog adapter | Quote unit tests do not use the widget |
| Hardcoded GST in the provider | Remove from the widget path you touch | Pricing tests |

Do not rewrite the whole 732-line file if you can extract the price step. If the extract exceeds the line budget, stop after the price step and leave other steps for M06.

## 5. Tasks

1. `test(pricing): gst splits and vehicle multiplier`.
2. `feat(api): seed catalog and add quotes`.
3. `refactor(booking): show the quote on the existing price step`.
4. `feat(catalog): cache services for offline read`.

## 6. Ports

`CatalogRepository`, `PricingService` (pure, in domain, both languages). Fake catalog in tests.

## 7. Files

`backend/app/domain/pricing.py`, `app/lib/features/booking/domain/pricing.dart` if the app must show a preview offline. Prefer calling the API when online and caching the last quote.

## 8. Branch and commits

Branch: `feat/m05-catalog-pricing`. Test commit first.

## 9. Tests

- `gst_on_59900_plus_4900_splits`
- `four_wheeler_labor_is_one_and_a_half`
- `inactive_service_is_rejected`
- `quote_does_not_write_a_booking`
- Widget: price step shows labor, fee, GST, total

## 10. Acceptance and manual check

- Given General Service and a bike, when the price step opens online, then the total matches the server quote.
- Given airplane mode and a fresh cache, when the list opens, then services still show with an updated-at label.
- Given a deactivated service, when quoted, then the API returns an error the step can show.

Manual: walk the wizard to the price step. Confirm the rupee figures. Do not need to place the booking.

## 11. Definition of done

- [ ] No price constant in the price-step widget.
- [ ] Tests listed above pass.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

Touching `booking_flow_screen.dart` can break later steps. Extract rather than rewrite. Revert the UI commit if the wizard cannot reach the address step.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M05 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M05-catalog-pricing.md. Do not create bookings or charge money. Branch feat/m05-catalog-pricing. Update docs/AGENT_PROGRESS.md and open a PR.
```
