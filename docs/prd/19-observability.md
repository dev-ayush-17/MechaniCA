# 19 — Observability

## Logging

JSON lines on stdout. Cloud Run sends them to Cloud Logging.

| Field | Required |
| --- | --- |
| `severity` | `INFO`, `WARNING`, `ERROR` |
| `message` | short |
| `requestId` | yes on requests |
| `userId` | if authenticated |
| `route` | template, not the raw path with secrets |
| `status` | HTTP |
| `latencyMs` | yes |
| `errorCode` | on failures |

Never log: Authorization header, OTP, webhook raw body, signed URL, service account.

Flutter logs in debug only, through `Logger`. Release builds log errors to the crash adapter in M16 and do not print PII.

## Metrics

Counters and timings, names stable:

| Metric | Alert |
| --- | --- |
| `http_requests_total` by route and status | 5xx rate over 2% for 5 minutes pages on-call |
| `booking_create_total` by result | none at MVP volume. Watch the dashboard |
| `payment_pending_age` | any pending over 30 minutes pages |
| `webhook_invalid_signature_total` | more than 5 in 10 minutes pages. Possible attack or key mismatch |
| `dispatch_failed_total` | more than 30% of confirms in an hour |
| `wallet_invariant_mismatch` | any value above 0 pages |
| `maps_route_calls` | more than 10 per booking per hour warns. Loop bug |
| `rtdb_location_writes` | more than 400 per booking per hour warns |

Paging at MVP can be email to the owner until a real on-call rotation exists. The alert still has a written threshold so it is not "ping me if it feels bad."

## Tracing

`X-Request-Id` is the correlation id across app, API, and task handler. Tasks pass the original id in the body and add their own. That is enough. OpenTelemetry is optional in M16 if logs are not enough. It is not required to start.

## Health

`GET /health` returns `{ "status": "ok" }` and does not touch Firestore. `GET /health/ready` checks Firestore and the task queue credentials. Cloud Run readiness uses `/health/ready`. Liveness uses `/health`.

## Incidents

| Severity | Example | First response |
| --- | --- | --- |
| SEV-1 | Payments marking paid without webhook verify, or rules allowing client status writes | Owner rotates affected secrets and deploys the fix. Agent sessions do not deploy prod. Stop feature work |
| SEV-2 | Dispatch failing for every booking, or API 5xx over 2% for 15 minutes | Roll back the Cloud Run revision. Feature freeze on that area |
| SEV-3 | One screen wrong, a non-money bug | Normal PR |

After SEV-1 and SEV-2, write a short note in `docs/incidents/YYYY-MM-DD-title.md` (folder created when the first incident happens): what broke, what the user saw, what we changed, what we will add a test for.

Rollback of the API is "route traffic to the previous Cloud Run revision." Rollback of the app is a store release, so the client must tolerate the previous API for one version. Additive JSON makes that realistic.

## User-facing failure copy

| Situation | Copy |
| --- | --- |
| Offline | "You're offline." |
| Timeout | "That took too long. Try again." |
| 500 | "Something went wrong on our side. Try again." |
| 503 | "Service is unavailable. Try again." |
| Maintenance | "MechaniCA is down for maintenance until {time}." |

Do not show exception text to users.
