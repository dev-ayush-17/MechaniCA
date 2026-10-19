# M01 — Frontend foundations

## 1. Goal

Make the demo analyzer-clean and remove dead structure without changing what a user sees on the live routes. Audit items assigned to M01 in [chapter 03](../prd/03-frontend-audit.md).

## 2. Prerequisites

M00 merged.

## 3. Scope

In: delete `lib/screens/` and `lib/theme/`. One theme. Remove unused packages that have no caller. Remove missing asset directories from pubspec or add the empty folders only if an asset is referenced. Replace `widget_test.dart`. Fix unused imports and the `prefer_const` issues enough that `flutter analyze` reports no issues. Add an ARB scaffold and move no more than the splash strings if a full extraction would exceed the line budget. Split nothing that changes layout.

Out: Freezed migration of every model, booking logic, auth behavior, folder moves of every feature into `domain/data`, visual redesign.

## 4. Existing code

| Path | Action | Safety net first |
| --- | --- | --- |
| `test/widget_test.dart` | Rewrite to pump `MechaniCAApp` and expect the splash title | This is the safety net |
| `lib/screens/*`, `lib/theme/*` | Delete after grep shows no live import | Widget test plus a manual launch |
| Duplicate permission files | Keep the file the router uses. Delete the unreferenced copy | Grep `LocationPermissionScreen` |
| `pubspec.yaml` unused deps | Remove `lottie`, `percent_indicator`, `dotted_border`, `flutter_staggered_animations`, `cached_network_image` if still unused | `flutter test` and launch |
| `app_providers.dart` and screens | Analyzer fixes only. No behavior edits | Existing flows still navigate |

## 5. Tasks

1. Write the splash widget test. Commit as `test(app): pump MechaniCAApp instead of MyApp`.
2. Delete dead screens and the duplicate theme. Commit `refactor(app): remove unused screens and theme`.
3. Remove unused packages and fix the asset paths. Commit `chore(app): drop unused dependencies`.
4. Fix remaining analyzer issues without changing copy. Commit `style(app): satisfy the analyzer`.
5. Add `flutter_localizations` and `lib/l10n/app_en.arb` with a handful of shared strings (offline banner text can wait). Commit `chore(app): add English string catalog`.
6. Tighten `analysis_options.yaml` with `avoid_print` and `prefer_const_constructors` if the tree is already clean.

## 6. Ports

None new. Use M00's `Logger` if you touch a `print`.

## 7. Files

Delete the dead paths. Do not delete `lib/features/**` routes. Do not delete fuel, membership, referral, or documents.

## 8. Branch and commits

Branch: `refactor/m01-frontend-foundations`. Commits are the task list. No `feat` commit unless a test-only change is mislabeled. There is no user-facing feature.

## 9. Tests

- `splash_shows_brand` pumps the app and finds MechaniCA.
- Optional: `empty_state_renders` for the shared widget. Skip goldens.

`flutter analyze` exits 0. `flutter test` exits 0.

## 10. Acceptance and manual check

- Given a fresh launch, when splash finishes, then onboarding still appears.
- Given OTP `123456`, when you sign in, then the five tabs still open: Home, My Bikes, History, Wallet, Profile.
- Given the fuel, membership, refer, and documents routes, when you open them from their existing buttons, then they still build.

Manual: walk those tabs and open booking until the first step. You are checking that nothing moved, not that booking is correct.

## 11. Definition of done

- [ ] Analyze and test are clean.
- [ ] Dead theme and dead screens are gone.
- [ ] Demo looks the same on the paths above.
- [ ] Progress file updated. PR opened.

## 12. Risks and rollback

Deleting a screen the router still imports will break the build. Grep before delete. Revert the delete commit if a route fails.

## 13. Execution prompt

```
You are implementing MechaniCA milestone M01 only. Read AGENTS.md, docs/PRD.md, docs/AGENT_PROGRESS.md, and docs/milestones/M01-frontend-foundations.md. Do not change booking, payment, or auth behavior. Do not redesign screens. The demo must look and navigate as it does now. Branch refactor/m01-frontend-foundations. Update docs/AGENT_PROGRESS.md and open a PR when analyze and tests pass.
```
