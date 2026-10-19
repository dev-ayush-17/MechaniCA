# M02 — Auth

## 1. Goal

Replace pretend OTP with `AuthService` and `AuthVerifier`, and bootstrap a user document. FR-AUTH-001 through FR-AUTH-005. [Chapter 11](../prd/11-authentication.md).

## 2. Prerequisites

M01 merged.

## 3. Scope

In: phone OTP fake adapter that still accepts `123456` only in dev. Firebase adapter behind `PROVIDER_AUTH=firebase`, used when the emulator is on. `POST /v1/me/bootstrap` and `GET /v1/me`. Role claim default `customer`. Mechanic intent creates a draft profile. Remove forgot-password from the router. Persist session across restart via the Auth SDK (fake adapter may use a debug secure flag in Drift only for the fake user id, never a raw production token). 401 handling. Generated OpenAPI client wired for these routes.

Out: Google sign-in implementation (flag off), admin roles, vehicle API.

## 4. Existing code

| Path | Action | Safety net |
| --- | --- | --- |
| `features/auth/login_screen.dart`, `otp_screen.dart` | Refactor to call the port. Keep the layout | Widget test: invalid phone disables the button. Dev hint `123456` visible only when `APP_ENV=dev` |
| `forgot_password_screen.dart` | Remove route. Keep permission screens if they live in that file. Move them out if needed without changing their look | Test that `/forgot-password` is gone |
| `repositories/auth_repository.dart` | Becomes the fake adapter or a thin wrapper. Do not leave two OTP implementations | Unit test the lockout counter |
| `lib/screens/login_screen.dart` | Already deleted in M01 | |

## 5. Tasks

1. Characterization tests for the login button and the OTP field.
2. `refactor(auth): call AuthService from the login flow` with the fake still accepting `123456` in dev and rejecting it when `APP_ENV=prod`.
3. `feat(api): verify bearer tokens and bootstrap users`.
4. `feat(app): generate the Dart client and use it in the auth adapter`.
5. `feat(auth): restore the session on launch`.
6. `refactor(auth): remove the forgot-password route`.

## 6. Ports

`AuthService`, `AuthVerifier`, `UserRepository`. Fakes first, Firebase adapter second. OpenAPI client is not a port. It sits inside the HTTP adapter.

## 7. Files

Create `app/lib/features/auth/{domain,data,presentation}` and move the screens in a refactor commit. Backend: `api/v1/me.py`, `application/bootstrap_user.py`, `adapters/fake/auth.py`, `adapters/firebase/auth_verifier.py`.

## 8. Branch and commits

Branch: `feat/m02-auth`. Sequence is the task list. Do not combine the route deletion with the Firebase adapter.

## 9. Tests

- `otp_lockout_after_five_failures`
- `bootstrap_is_idempotent`
- `prod_config_rejects_demo_otp`
- `missing_token_is_401`
- Widget: short phone number does not enable Continue

## 10. Acceptance and manual check

- Given dev, when you enter a valid number and `123456`, then home opens.
- Given a restart, when the fake or emulator session is valid, then you do not see onboarding.
- Given prod flavor config, when the code is `123456`, then sign-in fails.
- Given forgot-password, when you look at the router, then the path is absent.

Manual: sign in, kill the app, relaunch, confirm you land on home. Sign out, confirm login returns.

## 11. Definition of done

- [ ] Requirements above have tests.
- [ ] Demo OTP cannot succeed in a prod flavor.
- [ ] No JWT minted by our API.
- [ ] Progress updated. PR opened.

## 12. Risks and rollback

Firebase emulator auth is fiddly on Windows. The fake adapter must keep the demo usable if the emulator is down. Feature-flag the Firebase adapter. Rollback is the fake binding.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M02 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, docs/prd/11-authentication.md, and docs/milestones/M02-auth.md. Keep Riverpod. Do not build vehicles or payments. Branch feat/m02-auth. Update docs/AGENT_PROGRESS.md and open a PR.
```
