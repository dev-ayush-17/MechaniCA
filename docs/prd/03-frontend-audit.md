# 03 — Existing frontend audit

Written for someone who did not build the demo. The audit was done on `main` at commit `069f045` ("Implemented the frontend architecture demo"). The `develop` branch has an unmerged rename to MechUpp and some UI fixes. This spec follows `main` and does not merge `develop`.

## What exists

The repository has two projects and no docs until this phase.

| Path | What it is |
| --- | --- |
| `mechanica_app/` | Flutter demo. About 70 Dart files, ~11,600 lines under `lib/`. |
| `mechanica_api/main.py` | 28-line FastAPI stub. `POST /login` returns `mock_jwt_token_for_<phone>`. No `requirements.txt` on `main`. |
| Root | Git metadata and a short `.gitignore`. No CI, Docker, Firebase, or README before this phase. |

Flutter **3.44.6**, Dart **3.12.2**, SDK constraint `>=3.0.0 <4.0.0`. The package name is `mechanica_app`. Android application id is still `com.example.mechanica_app`. Minimum Android SDK is Flutter's default 24. There is no Google Maps key, no Firebase config, and no payment SDK.

`flutter analyze` (19 Oct 2026) reported **160 issues and 1 error**. The error is `test/widget_test.dart`, which pumps `MyApp`. The real class is `MechaniCAApp`, so the only test cannot compile. `flutter test` was not re-run for that reason. The other issues are unused imports, `prefer_const_constructors`, a deprecated `background` color in the unused `lib/theme/app_theme.dart`, and `pubspec.yaml` listing `assets/animations/` and `assets/icons/` even though those folders do not exist.

## How the demo is built

The good news: the skeleton is a normal Flutter app, not a pile of `setState`.

| Choice | Where | Verdict |
| --- | --- | --- |
| State | `flutter_riverpod` 2.6. `ProviderScope` in `lib/main.dart`. Notifiers in `lib/providers/app_providers.dart` (~625 lines). | Keep Riverpod. Split the one file later. |
| Navigation | `go_router` 13. Routes in `lib/navigation/app_router.dart` and `route_names.dart`. | Keep. |
| Theme | `lib/core/theme/app_colors.dart` and `app_theme.dart`. Dark theme, red `#E52C27`, Outfit font. | Keep the token file. |
| Data | `lib/repositories/*` and `lib/mock/mock_data.dart` (~750 lines). Every provider returns a mock. | Keep the repository idea. Replace the implementations one feature at a time. |
| Models | Plain Dart classes in `lib/models/`. No Freezed. `NotificationModel.isRead` is a mutable field. | Refactor to immutable models when each feature is touched. |

Sign-in is pretend. `MockAuthRepository` accepts OTP `123456` or any 6-digit code. Nothing is stored, so a restart always shows onboarding again. Splash waits 3 seconds and always goes to onboarding.

The active screens live under `lib/features/`. A bottom navigation shell (`MainShell`) has Home, My Bikes, History, Wallet, and Profile. About 40 routes are registered. Two route names are unused: `/bikes/edit` and `/support/tickets`.

`lib/screens/` (old splash, onboarding, and a login page that calls `http://10.0.2.2:8000/login` with Dio) is not registered in the router. `lib/theme/app_theme.dart` is a second theme used only by those dead screens. Several feature files are one-line `export` barrels; the real widget sits in a parent file. `forgot_password_screen.dart` also contains the location and notification permission screens, which exist again as their own files.

Shared widgets worth keeping: `AppButton`, `AppTextField`, `AppCard`, snackbar helper, shimmer, `EmptyState`, `ErrorState`, `StatusBadge`, `SectionHeader` in `lib/widgets/shared/`.

## Quality scores

Scores are out of 10. They describe the demo, not the people who wrote it.

| Area | Score | Why |
| --- | --- | --- |
| Structure | 4 | Feature folders exist, then god files, barrel files, and a dead `lib/screens` tree. |
| State management | 7 | Riverpod is the right tool and it is actually used. One giant provider file and empty `catch` blocks keep it from an 8. |
| Widget size and reuse | 4 | Shared buttons exist. `home_screen.dart` is ~716 lines and `booking_flow_screen.dart` is ~732. |
| Naming | 6 | Names are readable. The domain says "bike" and "pickup" while the product is "vehicle" and "mechanic comes to you". |
| Error handling | 3 | Failures are swallowed (`catch (_) {}` in `app_providers.dart`). Booking details fall back to the first mock booking if the id is missing. |
| Null safety | 7 | The code compiles in null-safe Dart. A few `as` casts and `firstWhere` calls can still throw. |
| Theming | 6 | Tokens exist and the dark theme is consistent. A second theme file contradicts it. |
| Performance | 5 | No measured jank. Google Fonts are fetched at runtime. Lists are small because the data is fake. |
| Accessibility | 1 | No `Semantics` widgets. Tap targets and contrast were not audited on a device. |
| Tests | 1 | The generated counter test does not compile. No repository tests. |
| Lint cleanliness | 4 | Default `flutter_lints` only. 160 analyzer issues. Analyzer is not in CI. |

## Screen map

| Route | File | What the user can do today | MVP feature |
| --- | --- | --- | --- |
| `/` | `features/auth/splash_screen.dart` | Wait, then onboarding | Auth |
| `/onboarding` | `features/auth/onboarding_screen.dart` | Three intro pages | Auth |
| `/login`, `/otp` | `features/auth/login_screen.dart`, `otp_screen.dart` | Phone and a fake OTP. Google button does nothing real | Auth |
| `/forgot-password` | `features/auth/forgot_password_screen.dart` | Looks like password reset. Product uses OTP, so this screen is the wrong model | Auth, delete or replace |
| `/location-permission`, `/notification-permission` | Duplicated in the forgot-password file and in standalone files | Explain and continue. No real permission request | Auth |
| `/home` | `features/home/home_screen.dart` | Banners, active booking, services, bike card | Dashboard |
| `/notifications` | `features/home/notifications_screen.dart` | List, mark read, delete, all local | Notifications |
| `/bikes`, `/bikes/add`, `/bikes/details` | `features/bikes/my_bikes_screen.dart` | List, add, details. Both mock bikes share registration `BR80Y 024` | Vehicles |
| `/booking` and success, details, reschedule | `features/booking/*` | Six-step wizard. Coupon codes `FLAT20`, `ARC049`, `WASH110` are checked in the widget | Booking |
| `/tracking`, `/tracking/progress` | `features/tracking/live_tracking_screen.dart` | A timer advances a fake status. No map | Tracking |
| `/emergency` | `features/emergency/emergency_screen.dart` | SOS-styled UI, then a fake tracking screen | SOS booking |
| `/inspection`, gallery | `features/inspection/digital_inspection_screen.dart` | Before/after photos from Unsplash, parts list | Parts proof, customer view |
| `/invoice` | `features/invoice/invoice_screen.dart` | Always shows the first mock invoice. Share is a snackbar | Invoice |
| `/wallet`, `/wallet/add` | `features/wallet/wallet_screen.dart` | Balance and fake top-up | Wallet |
| `/offers` | `features/offers/offers_screen.dart` | Coupon list | Coupons |
| `/history`, detail | `features/history/history_screen.dart` | Past bookings | History |
| `/profile` and edit, addresses, settings | `features/profile/profile_screen.dart` | Profile, two Patna addresses, toggles that reset on restart | Profile |
| `/support`, chat, ticket | `features/support/support_screen.dart` | FAQ, fake chat replies, one ticket | Disputes later. Chat here is support, not the mechanic |
| `/health` | `features/health/health_score_screen.dart` | Score for hardcoded `bike_001` | Vehicle health |
| `/fuel` | `features/fuel/fuel_tracker_screen.dart` | Fuel chart | Phase 2. Keep the screen |
| `/membership`, `/refer` | `features/membership/membership_screen.dart` | Plans and referral | Phase 2. Keep the screen |
| `/documents` | `features/documents/documents_screen.dart` | RC, insurance, PUC placeholders | Phase 2. Keep the screen |

There is no mechanic UI, no admin UI, no real map, no real payment, and no push notification code.

## Classification

| Module | Class | Why | Milestone |
| --- | --- | --- | --- |
| Riverpod and go_router | Keep | They are used correctly. Replacing them would be churn. | M01 documents the rule. No migration. |
| `lib/core/theme` | Keep | Real tokens. Make them the only theme. | M01 |
| `lib/widgets/shared` | Keep | Small and reused. | M01 |
| Offers screens | Refactor | Structure is fine. Coupon checks must move to the server. | M10 |
| History screens | Refactor | Right screen, mock data, large file. | M14 |
| Auth feature | Refactor | Flow is usable. Session, real OTP, and deletion of the password screen are missing. | M02 |
| Home | Refactor | Right dashboard idea, 700-line file, hardcoded user. | M14 for the split. M01 does not rewrite it. |
| Bikes | Refactor | CRUD shape is right. Domain becomes Vehicle. Fix duplicate registration numbers in fixtures. | M03 |
| Booking | Refactor | Wizard stays. Pricing and status machine move out of the widget. | M05, M06 |
| Invoice | Refactor | Load by booking id. PDF comes from the server. | M11 |
| Wallet | Refactor | UI first, ledger from the server. | M10 |
| Profile | Refactor | Forms stay. Persist through the API and the local cache. | M14 |
| Health | Refactor | Per vehicle, not a constant. | M14 |
| Inspection | Refactor | Becomes the customer view of parts photos. | M13 |
| Support FAQ | Refactor | Static FAQ can stay local. Tickets wait for admin disputes. | M15 |
| Tracking | Rewrite behavior | The widget can stay as a shell. The timeline animation is not tracking. | M08 |
| Emergency | Rewrite behavior | Keep the urgency UI. Wire it to priority dispatch. | M06, M07 |
| `lib/screens`, `lib/theme` | Delete | Dead duplicates. The login screen is the only caller of the mock API. | M01 |
| Duplicate permission screens | Delete | One copy, and it should call the real permission APIs. | M01, M02 |
| Fuel, membership, referral, documents | Keep visible, no backend | Out of MVP. Do not break navigation. | None, except "demo still runs" |
| Mechanic app, admin, maps, payments, push, offline DB, security rules, tests | Missing | Not in the demo. | M00–M16 as assigned in the milestone index |

## Packages

Used on the live routes: `flutter_riverpod`, `go_router`, `google_fonts`, `shimmer`, `carousel_slider`, `smooth_page_indicator`, `flutter_animate`, `fl_chart`, `pinput`, `intl`.

Declared and unused in live code: `lottie`, `percent_indicator`, `dotted_border`, `flutter_staggered_animations`, `cached_network_image`, `shared_preferences`, `url_launcher`, `image_picker`, `share_plus`, `path_provider`. `dio` is imported only by the dead login screen. M01 removes the ones that still have no caller. Packages the MVP needs (`image_picker`, `share_plus`, `url_launcher`, `shared_preferences` or a secure store) come back in the milestone that uses them, pinned, with a one-line reason.

## Mock data the backend must not copy blindly

`lib/mock/mock_data.dart` is useful as a fixture shape and dangerous as a schema.

| Fixture | Keep as an idea | Redesign |
| --- | --- | --- |
| User | id, name, phone, email, photo | Wallet balance and loyalty points are not fields on the user document. They are ledgers. Membership plan is Phase 2. |
| Bikes | brand, model, year, registration, odometer, color, primary flag | Rename to vehicles. Add `vehicleType`. Registration must be unique per user. Both fixtures currently share `BR80Y 024`. |
| Services | id, name, description, price, duration, includes | This is a catalog in the database, not a Dart list. Price is an input to the estimate engine, not the customer's final total. |
| Bookings | ids, schedule, coupon, GST, mechanic display fields | Status enum is the workshop flow (`pickedUp`, `inWorkshop`, `outForDelivery`). Replace it. Do not store mechanic phone in the customer booking payload; masking needs a separate number. |
| Wallet transactions | credit/debit list | Append-only ledger written by the server. |
| Offers | code, percent or flat, min order, expiry | Server-side rules, redemption count, first-booking flag. |
| Inspection | before/after photos, parts | Becomes parts-proof records with timestamps and a storage path. Unsplash URLs are not the model. |
| Addresses | label, lines, city, pincode, default | Add lat/lng from geocoding. Patna samples can stay as dev fixtures. |
| Health score | category scores | Computed or curated per vehicle. Do not ship one global score. |

Hardcoded demo values to remove from widgets when that feature is wired: user id `usr_001`, pickup fee `100` inside the provider, support number `+91 9206 06199`, profile copy "₹2,150 Saved", fuel "₹1,250 This Month". Demo OTP `123456` may exist only in the fake auth adapter.

## What this means for the build

The demo is a clickable map of the customer app. M01 cleans the foundations without changing what the screens show. Each later milestone replaces mock behavior for one feature and leaves the others on the fake adapter. The look stays unless a screen is clearly wrong. The workshop status names are clearly wrong for this product, so they change in M06 even though the wizard layout stays.
