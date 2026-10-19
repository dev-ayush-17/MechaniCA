# Architecture decisions

| ADR | Decision |
| --- | --- |
| [001](001-product-name.md) | Keep the name MechaniCA |
| [002](002-on-site-fulfillment.md) | Mechanic comes to the vehicle. Workshop pickup is Phase 2 |
| [003](003-one-flutter-package.md) | One Flutter package, three entrypoints, including admin web |
| [004](004-riverpod-go-router.md) | Keep Riverpod and go_router |
| [005](005-result-and-freezed.md) | Sealed `Result` and Freezed models |
| [006](006-drift.md) | Drift for the offline cache |
| [007](007-rtdb-location.md) | Realtime Database for live location only |
| [008](008-cloud-tasks.md) | Cloud Tasks plus Scheduler. No Cloud Functions |
| [009](009-firebase-auth.md) | Firebase phone OTP as the default auth adapter |
| [010](010-cashfree-and-maps.md) | Cashfree and Google Maps behind ports |
| [011](011-repo-layout.md) | Move to `app/`, `backend/`, `firebase/`, `docs/` in M00 |
| [012](012-openapi-client.md) | Generate the Dart API client from OpenAPI |
| [013](013-sequential-dispatch.md) | Offer a job to one mechanic at a time |
| [014](014-server-writes.md) | FastAPI is the only writer for status and money |
| [015](015-swagger-parser.md) | Generate the Dart client with swagger_parser |

Each note is the choice a later milestone must follow unless a new ADR replaces it.
