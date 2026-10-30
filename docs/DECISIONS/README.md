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
| [016](016-product-name-mechupp.md) | Product name becomes MechUpp |
| [017](017-spark-http-with-fake-auth.md) | Spark: fake OTP, HTTP API, Firestore Admin SDK |
| [018](018-walkthrough-dispatch-and-flavors.md) | Accept gate, Firestore offers, demo wallet float, two APK flavors |
| [019](019-mechanic-session-ticker.md) | Heartbeat and offer poll live for the mechanic session, not only home |

Each note is the choice a later milestone must follow unless a new ADR replaces it.
