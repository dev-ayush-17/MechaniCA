# Agent progress

Living log. Update this at the end of every session.

## Current

| Field | Value |
| --- | --- |
| Phase | Implementation |
| Branch | `feat/m05-catalog-pricing` |
| Milestone in progress | M05 catalog and pricing. Code and tests are done. PR opening. |
| Next milestone | M06 bookings. Needs M04 and M05 both merged (M04 is already on `main`). |
| Demo | Runs from `app/` with `flutter run`. Service step reads the seeded catalog. Price step shows a server quote (labor, fee, GST, total). Confirm still uses the demo booking mock. |
| Known broken | Nothing known. `flutter analyze` reports no issues |

## Completed

| When | What |
| --- | --- |
| 2026-10-19 | Frontend audit on `main` (`069f045`). Flutter 3.44.6, Dart 3.12.2. `flutter analyze`: 160 issues, 1 error (`MyApp` in `widget_test.dart`) |
| 2026-10-19 | PRD chapters 01–25, ADRs 001–014, agent rules, milestone specs (PR #3) |
| 2026-10-19 | M00 foundation (PR #4), M01 frontend foundations (PR #5), M02 auth (PR #6), rename to MechUpp (PR #7), M03 vehicles (PR #9), M04 mechanics (PR #8). All merged. |
| 2026-10-19 | M05: pure `PricingService` (Python and Dart), integer paise GST split, four-wheeler labor × 1.5 from config (15000 bps). Seeded five PRD services. `POST /v1/quotes` has no booking write. Price step shows the quote. Drift catalog cache 24h with an "Updated" label. |

## M05 notes and follow-ups

| What | Where |
| --- | --- |
| `PricingService` (pure, integer paise) | `backend/app/domain/pricing.py`, `app/lib/features/booking/domain/pricing.dart` |
| `CatalogRepository` fake + Firestore, bound in `deps.py` | `backend/app/ports/catalog_repository.py`, adapters |
| `GET /v1/catalog/services`, `POST /v1/quotes` | `backend/app/api/v1/catalog.py`, `quotes.py` |
| OpenAPI + generated Dart client | `backend/openapi.json`, `app/lib/core/api/generated/` |
| Price and service steps extracted | `app/lib/features/booking/presentation/` |
| Offline catalog + last quote cache (Drift schema 2) | `app/lib/data/local/`, `features/catalog/data/` |

Decisions:

- GST is 18% on labor + convenience fee + parts. CGST/SGST split so they differ by at most 1 paise. Discount is subtracted from the total, not from the GST base. The chapter 12 sample with `discountPaise: 5000` and `totalPaise: 70664` is off by 100 paise from that rule (`70564`). M05 tests use the zero-discount glossary sample (`76464`).
- Four-wheeler labor multiplier is config `four_wheeler_labor_bps=15000` (1.5x), not a binary float.
- Empty coupon code means no discount. A non-empty code returns `invalid_input` "Coupons arrive in M10." The price step sends an empty code so the wizard can reach the estimate. The address-step demo coupons stay local until M10.
- Quotes assume `two_wheeler` from the demo bike step (`BikeModel` has no vehicle type). Four-wheeler labor is covered by API/unit tests.
- `MockServiceRepository` is replaced by `FakeCatalogServiceRepository` (PRD seed). The booking wizard reads `CatalogRepository` from `composition/providers.dart`.
- Diff is a bit over 1,500 lines excluding generated OpenAPI/Dart client (four commits, no extra milestone split). Generated client files are excluded from that count.

Follow-ups, not done here (scope):

- Booking create (M06) must call the same `PricingService` and snapshot the estimate.
- Coupon redeem (M10).
- Wire the address-step coupon field to `POST /v1/quotes`.
- Price step still does not create a payment (M08).
- Confirm booking still writes a mock `BookingModel` with leftover float totals. Replace in M06.
- Bike step still uses `BikeModel` / `MockBikeRepository`. Vehicle type for quotes should come from the M03 vehicle when the wizard is rewired.

## Not verified locally

- Firestore rules tests (`firebase/tests/rules.test.js`), including the new catalog read/write cases, were **not run**. This machine has no Java. The `firebase-rules` CI job installs Java 21 and runs them.
- `FirestoreCatalogRepository` has not run against the emulator.
- The app was not built for Android or iOS here. Manual wizard walk to the price step was not run (no device). Widget tests cover the price-step figures and the bike-step characterization.
- The `api-client` CI job is the check that OpenAPI and the Dart client stay in lockstep.

## Open items that do not block the next milestone

- Production Firebase and GCP projects (owner).
- Cashfree and Google Maps keys (owner).
- Owner: enable GitHub branch protection on `main`.

## Next session

M06 bookings per [MILESTONES.md](MILESTONES.md). Start only after this M05 PR is merged (M04 already is).
