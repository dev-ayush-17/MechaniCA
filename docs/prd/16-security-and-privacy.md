# 16 — Security and privacy

## Threat model (MVP)

| Threat | What goes wrong | Control |
| --- | --- | --- |
| Client writes a paid booking | Free service | Rules deny writes. API checks status machine. Tests call Firestore as a user and expect denial |
| Forged webhook | Mark unpaid jobs paid | Signature verify before parse side effects. Mismatch alerts |
| IDOR on booking id | Read someone else's job | API checks party or staff. Rules match the same condition for direct reads |
| OTP brute force | Account takeover | Lockout, resend caps |
| Stolen phone session | Attacker acts as the user | Short-lived ID token, revoke on suspend, sign-out clears local data |
| Mechanic sees customer phone | Harassment after the job | Masked calling. Chat only inside the booking window. Phone not in the booking JSON for the other party |
| Tracking link forwarded | Stranger watches a trip | 6 hour token, no PII beyond first name and vehicle label, dies when the job ends |
| Parts photo contains a face or a plate of a bystander | Extra PII | We still store it as job evidence. Hide action for abuse. Retention 1 year, then delete the file and keep the audit row |
| Admin account takeover | Full data access | Super-admin seeded, not self-serve. Audit log. Rate limit admin login the same as OTP |
| GPS drift or fake GPS | Wrong arrival | Arrival is a mechanic action, not a geofence write. Fake GPS is not fully solvable. Stale and jump filters reduce noise |
| Denial of service | API bill or outage | Rate limits, Cloud Run max instances, request size 1 MB except signed uploads which go to Storage |
| Secrets in git | Key leak | `.gitignore`, `.cursorignore`, CI secret scan in M16, PR review |
| Log injection of OTP | OTP in a log file | Logger drops sensitive keys. Code review on auth routes |

We do not claim to stop a rooted phone from mocking GPS. We do claim the server will not take that phone's word for payment or status.

## PII inventory

| Data | Where | Who can read | Retention |
| --- | --- | --- | --- |
| Phone | Auth and user doc | Self, admin, support | Life of account, then 30 days |
| Name, email | User doc | Self, staff | Same |
| Precise live location | RTDB | Parties during the job | 7 days after terminal status |
| Job address | Booking snapshot | Parties, staff | 1 year |
| Registration number | Vehicle and snapshot | Owner, assigned mechanic, staff | Life of vehicle. Snapshot 1 year |
| Government id images | Storage | Owner, admin | Delete 90 days after verification decision. Keep the decision in the audit log |
| Chat | Firestore | Parties, support if a dispute opens | 1 year |
| Parts photos | Storage | Parties, staff | 1 year |
| Payment ids | Firestore | Staff, and the payer sees status | 8 years for tax invoices. Confirm with the team's accountant before shortening. **Assumption:** 8 years |
| Invoice PDF | Storage | Customer, staff | 8 years |

Deletion: `POST /v1/me/deletion-request` is Phase 2 as a self-serve flow. MVP: support can suspend and admin can run a documented script to delete the user doc, vehicles, and sessions, and to keep invoices that the law requires. The script is specified in M16 and is not a silent hard delete of financial records.

## Location privacy

- Foreground disclosure before the first publish: "MechaniCA uses your location during an active job so the other person can find you."
- Background disclosure is the Android notification and the iOS permission string.
- The tracking link recipient is a guest. They do not get an account and we do not drop a cookie that identifies them beyond standard server logs of the token id.
- Do not put raw location in analytics.

## Phone masking

`TelephonyPort` returns a number that bridges the call. Our logs store the booking id and the call start, not the underlying numbers, if the provider's webhook includes them. Drop them in the adapter.

Until a provider is contracted, the Call button stays behind a flag. Shipping the real phone "temporarily" is not allowed.

## Abuse

| Abuse | Response |
| --- | --- |
| Chat spam | 20 messages per booking per 10 minutes. Then `429` |
| Review bombing | One review per booking. Text filtered for phone numbers |
| Coupon sharing | Per-user limit and first-booking flag |
| Fake mechanic docs | Human review. No auto-approve |
| SOS abuse | Same account limits as booking. A customer with 3 failed or cancelled SOS jobs in 24 hours must contact support for the next one. `429` `sos_limited` |

Blocked words for reviews are a config list, not a machine-learning model.

## Rate limits

Per user id and per IP, token bucket, returned as `429` with `Retry-After`.

| Route group | Limit |
| --- | --- |
| OTP request | 5 / hour / phone |
| Booking create | 10 / hour / user |
| Payment create | 10 / hour / user |
| Chat send | 20 / 10 min / booking |
| Admin write | 60 / min / actor |
| Public tracking | 60 / min / IP |
| Webhook | 300 / min / IP, and signature still required |

## India DPDP Act (practical checklist)

This is an engineering checklist, not legal advice. The owner should have a lawyer read the customer-facing policy before production launch.

- Collect the minimum: phone, name, vehicle, job address, photos the job needs.
- Purpose is stated on the permission screens and in a privacy policy URL in settings. The policy page can be a static doc in M16.
- Consent for location is the OS permission plus our sentence. Denying location still allows booking on a saved address.
- Consent for notifications is separate. Denying it does not block booking. SMS remains optional.
- A grievance contact (email and phone) is config, shown in settings.
- No sale of personal data. Analytics adapter must not send PII to an ad network. MVP analytics can be our own logs.
- Children's data: the product is not for under-18s. Onboarding checkbox "I am 18 or older" stored as `adultConfirmedAt`. This is a speed bump, not an identity proof.
- Cross-border: keep Firebase and Cloud Run in India (`asia-south1`) so we are not casually exporting location data. If a vendor processes outside India, record it in this chapter before enabling the adapter.

## Secure development

- Dependencies pinned. Renovate or a manual monthly bump. No wildcard versions in pubspec or pyproject.
- Service account JSON is a local file for the emulator only, gitignored, never in the Docker image.
- Admin SDK credentials on Cloud Run use the runtime service account, not a key file.
- CORS is an allow-list. `*` is a bug.
- Security rules are tested with the emulator rules unit tests in M00's skeleton and expanded in each milestone that adds a collection.
- A `security.mdc` rule tells agents not to log secrets and not to weaken rules to make a test pass.

## Incident basics

See [observability](19-observability.md). Security incidents (leaked key, rules mis-deploy, webhook bypass) are stop-the-line: rotate the secret, deploy the rules fix, and write an audit note. Production deploy and key rotation are owner actions. An agent session stops and asks.
