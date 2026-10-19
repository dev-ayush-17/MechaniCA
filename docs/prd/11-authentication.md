# 11 — Authentication

## Goal

The app knows who is calling. The server decides what they are allowed to do. The vendor that sends the SMS can change without a new booking flow.

## Default

Firebase Authentication, phone provider, India. The Flutter `AuthService` adapter wraps the Firebase Auth SDK. FastAPI never trusts the phone number in the body. It trusts the verified token.

`AuthVerifier` uses the Firebase Admin SDK to check:

- signature
- expiry
- audience / project id matches `FIREBASE_PROJECT_ID`
- token was not revoked (`check_revoked=true` on sensitive routes: payments, role changes, verification)

Principal:

| Field | Source |
| --- | --- |
| `userId` | `uid` |
| `role` | custom claim `role`, default `customer` if missing and the user doc says customer |
| `mechanicVerified` | custom claim, mirrored from the mechanic document |
| `authTime` | token |

If the claim and the user document disagree, the document wins and the API refreshes the claim.

## Session on the phone

- Firebase Auth persists the session in the platform secure storage it already uses.
- We do not copy the refresh token into Drift or SharedPreferences.
- Access token is attached by the HTTP adapter as `Authorization: Bearer`.
- On 401, refresh once. If that fails, sign out locally and route to login.
- Sign-out clears Drift for that user id and the upload queue.

There is no separate MechaniCA JWT in MVP. The stub that returned `mock_jwt_token_for_<phone>` is removed in M00.

## Sign-up and bootstrap

1. User verifies OTP.
2. App calls `POST /v1/me/bootstrap` with the bearer token and `{ "name"?: string, "intent": "customer" | "mechanic" }`.
3. If no user doc exists, the API creates one. `intent=mechanic` creates a mechanic profile in `draft` and sets role claim `mechanic`. `intent=customer` sets `customer`.
4. A phone cannot bootstrap a second role. The second intent returns `409 role_exists`.

Inviting an admin is not a public bootstrap. A super-admin calls `POST /v1/admin/users/{id}/role` with `{ "role": "admin" | "support" }`. The first super-admin is seeded with a script that the owner runs locally against the emulator or, later, a one-off command. The script is not an endpoint.

## Roles

| Claim | How it is granted |
| --- | --- |
| `customer` | Bootstrap |
| `mechanic` | Bootstrap intent |
| `support` | Super-admin |
| `admin` | Super-admin |
| `super_admin` | Seed script only |

Rules and the API both check the role. Hiding a button is not the control.

## Phone change, Google, email

- Changing phone is Phase 2 (`FR` not in MVP). The phone on the profile is the auth phone.
- Google: `AuthService.signInWithGoogle` exists on the port. The adapter returns `Unavailable` with code `provider_disabled` until `auth_google_enabled` is true and a real adapter is filled in. The button is hidden when the flag is false.
- Email and password: no port methods. Adding them later means extending `AuthService` and `AuthVerifier` together. Do not add a password field to the user document "for later."

## Swapping the auth vendor later

1. Implement `AuthService` for the new vendor on Flutter.
2. Implement `AuthVerifier` on FastAPI for the new token format.
3. Change `PROVIDER_AUTH` and the verifier binding.
4. Migrate users: the hard part is uid stability. If uids change, write a one-time map from old uid to new uid and keep `userId` in our database as our id, separate from the vendor uid.

**Decision now:** our `userId` equals the Firebase uid, because we have no users in production. The user document includes `authProvider` and `authSubject` so a future migration can detach them. New code uses `userId`. It does not assume the string shape of a Firebase uid beyond "opaque string."

## OTP abuse

| Control | Value |
| --- | --- |
| Resend cooldown | 30 seconds |
| Sends per phone per hour | 5 |
| Failed verifies before lock | 5 |
| Lock | 15 minutes |
| App check / Play Integrity | Should in M16, not a launch blocker for the emulator |

The fake adapter enforces the same counters so the UI can be tested.

## Mechanic versus customer apps

Both apps use the same Firebase project and the same token. The mechanic entrypoint calls bootstrap with `intent=mechanic`. If a customer token opens the mechanic app, the app shows "This phone is registered as a customer" and does not offer a role switch. The customer app does the mirror check.

## What the client stores

Allowed: display name cache, vehicles, drafts.

Not allowed: the ID token inside our own tables, Aadhaar numbers, full government id images on disk after a successful upload (delete the local file after the queue ack).
