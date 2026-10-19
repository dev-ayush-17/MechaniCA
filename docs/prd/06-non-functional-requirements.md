# 06 — Non-functional requirements

Numbers are requirements. "Fast" is not a requirement.

## Performance

Measured on a mid-range Android phone (2 GB free RAM class) and a release build, 4G profile (10 Mbps down, 50 ms RTT) unless noted.

| ID | Target |
| --- | --- |
| NFR-PERF-001 | Cold start to first frame of splash: p75 under 2.5 seconds. |
| NFR-PERF-002 | Home interactive (cached data): p75 under 1 second after process start when a session exists. |
| NFR-PERF-003 | `POST /v1/bookings` server time: p95 under 400 ms, excluding Cashfree and Maps. |
| NFR-PERF-004 | Dispatch candidate query: p95 under 300 ms for 1,000 online mechanics in one city. |
| NFR-PERF-005 | Map screen shows the last known points within 1 second of open, then refreshes. |
| NFR-PERF-006 | API error responses: p95 under 200 ms for validation failures (no downstream call). |
| NFR-PERF-007 | PDF generation: p95 under 5 seconds. The HTTP request returns `202` and the client polls or waits for the notification if it would block the payment response. Payment `paid` must not wait on the PDF. |
| NFR-PERF-008 | Scroll on history and wallet lists of 200 rows stays at 55 fps or better in profile mode. Use list virtualization, which Flutter `ListView.builder` already does. Do not load all pages at once. |

## Scalability and availability

| ID | Target |
| --- | --- |
| NFR-SCALE-001 | MVP design load: 50 concurrent bookings in one city, 200 online mechanics, 20 requests/second on the API. Not a national launch architecture. |
| NFR-SCALE-002 | Horizontal scale is Cloud Run instances, min 0 in dev, min 1 in prod to avoid cold start on payment webhooks. |
| NFR-AVAIL-001 | API monthly availability target 99.5% excluding planned maintenance. Planned maintenance is announced in-app 24 hours ahead and lasts at most 30 minutes. |
| NFR-AVAIL-002 | Firebase outage: booking create fails closed with "Booking is unavailable. Try again." Reads of cached profile and history still work. |
| NFR-AVAIL-003 | Cashfree outage: online pay shows "Payment provider is unavailable." Cash and, if the wallet already has funds, wallet still work. |

## Offline behavior

The app is local-first for reads and drafts. It is not an offline marketplace. Money and dispatch require a connection.

| Data or action | Offline behavior |
| --- | --- |
| Profile, vehicles, addresses, emergency contacts | Read from Drift. Edits queue. |
| Service catalog | Read cache up to 24 hours, then show the cache with "This list may be out of date." |
| Booking history and invoices metadata | Read cache. PDF download needs a connection. |
| Wallet balance | Show cached balance with "As of <time>. Connect to refresh." Hide Add money. |
| Booking draft | Saved locally. Confirm disabled. |
| Create booking, pay, cancel, accept job, change status | Blocked with a clear sentence. Not queued. |
| Chat text | Queued. |
| Parts and review photos | Queued. Server remains the authority on completion. |
| Live map | Last points only, labelled stale. No new route. |
| Sign-in | Blocked. |

| ID | Requirement |
| --- | --- |
| NFR-OFF-001 | A banner is visible on every screen while `connectivity` is offline: "You're offline." It does not cover the primary button. |
| NFR-OFF-002 | Queued writes show a count on the profile tab: "2 changes waiting to send." |
| NFR-OFF-003 | Queue retries use exponential backoff: 2s, 4s, 8s, 16s, then every 60s. Stop after 24 hours and mark the item failed with a retry button. |
| NFR-OFF-004 | The queue is per user and wiped on sign-out. |
| NFR-OFF-005 | Airplane mode during an active booking does not cancel it. |

## Accessibility

| ID | Requirement |
| --- | --- |
| NFR-A11Y-001 | WCAG 2.2 AA for text contrast on the dark theme. Primary red on near-black must be checked. If `#E52C27` fails for body text, use it for buttons and a lighter token for text. |
| NFR-A11Y-002 | Interactive targets are at least 48 by 48 dp. |
| NFR-A11Y-003 | Every icon-only button has a tooltip and a semantics label. |
| NFR-A11Y-004 | Form errors are text under the field, not color alone. |
| NFR-A11Y-005 | Status is text, not only a colored badge. |
| NFR-A11Y-006 | Support Dynamic Type / system text scale up to 1.6 without overlapping the booking total. |
| NFR-A11Y-007 | The map is not the only way to learn ETA. Distance and ETA are text. |

## Localization

| ID | Requirement |
| --- | --- |
| NFR-I18N-001 | User-facing strings live in ARB files from M01 onward for any new or touched screen. Existing screens move when their milestone touches them. |
| NFR-I18N-002 | English (`en`) is complete for MVP. Hindi (`hi`) is added in M16 for the booking, tracking, payment, and SOS flows at minimum. |
| NFR-I18N-003 | Dates and money use `intl` with `en_IN`: `₹1,299` and `19 Oct 2026, 4:30 pm`. |
| NFR-I18N-004 | No string concatenation for sentences that would break Hindi word order. Use placeholders. |

## Devices and OS

| ID | Requirement |
| --- | --- |
| NFR-DEV-001 | Android API 24 through the current stable API. iOS 15 through the current stable. |
| NFR-DEV-002 | Phones with width 360 dp to 430 dp. Below 360 dp, content scrolls. It does not clip the total. |
| NFR-DEV-003 | Portrait lock stays, matching `main.dart` today. |
| NFR-DEV-004 | Admin web: current Chrome and Edge, width ≥ 1024 px. Below that, show "Use a larger screen for admin." Do not build a phone admin. |
| NFR-DEV-005 | Release builds disable the demo OTP hint. |

## Battery and location

| ID | Requirement |
| --- | --- |
| NFR-BAT-001 | Location collection runs only during the windows in FR-TRK-004. |
| NFR-BAT-002 | A 30 minute en-route session should send at most 360 location writes (5 second duty). Typical moving traffic should be closer to 120–180. |
| NFR-BAT-003 | The foreground notification is required on Android while background updates run, and it has a Stop sharing action that only turns off the customer's own share. It does not cancel the booking. |

## Privacy and security NFRs

Detailed controls are in [security](16-security-and-privacy.md).

| ID | Requirement |
| --- | --- |
| NFR-SEC-001 | PII at rest in Firestore is access-controlled. Backups are in the same cloud project. No PII in analytics event properties (no phone, no exact address, no registration). |
| NFR-SEC-002 | Transport is HTTPS only. The emulator is the only HTTP exception, and only on localhost. |
| NFR-SEC-003 | Secrets are not in git. CI uses the host's secret store. |
| NFR-SEC-004 | Admin and payment routes are rate limited. See chapter 16. |
| NFR-SEC-005 | Dependency review: a new package needs a one-line reason in the PR and a pinned version. |

## Maintainability

| ID | Requirement |
| --- | --- |
| NFR-MAIN-001 | A new teammate can follow one booking create from the button to the repository using the learning notes and the folder layout, without asking which file is "the real one." |
| NFR-MAIN-002 | Vendor SDK imports exist only under adapter folders. A lint or CI check fails the build otherwise. |
| NFR-MAIN-003 | The OpenAPI spec and the generated Dart client are produced in CI. A drift check fails the build. |

## Logging

| ID | Requirement |
| --- | --- |
| NFR-LOG-001 | Every API request logs `requestId`, `userId` (if any), route, status, and latency. It does not log OTP, tokens, or full payment payloads. |
| NFR-LOG-002 | The client sends `X-Request-Id` (UUID). The server echoes it. |
