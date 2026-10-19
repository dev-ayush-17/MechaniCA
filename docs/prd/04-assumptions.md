# 04 — Assumptions and open decisions

**Decision** means this spec chooses it. Changing it later needs an ADR. **Assumption** means the team has not confirmed it, and the default is what we will build until someone changes the config or the ADR. **Open** means a teammate owns the final vendor, and the port exists so their choice does not rewrite the app.

## Decisions

| Topic | Choice | Why not the alternative | Change cost |
| --- | --- | --- | --- |
| Product name | MechUpp (ADR-016) | Was MechaniCA until the owner requested a single product name rename. | Low. ADR-016. |
| Fulfillment | Mechanic comes to the vehicle | The demo's pickup and workshop states describe a different product. Workshop mode is Phase 2, behind a service-mode flag, not a rewrite. | High if we keep both in MVP. We will not. ADR-002. |
| Booking kinds | Instant and scheduled | The demo already collects a date and time. Dropping scheduled booking would throw away a working wizard step. | Low. |
| Customer and mechanic apps | One Flutter package, two entrypoints (`main_customer.dart`, `main_mechanic.dart`) | Two packages would duplicate the API client and the design tokens. | Medium. ADR-003. |
| Admin UI | Flutter web entrypoint in the same package | A React admin adds a second language for a team that is still learning the first backend. | Medium. Revisit if data tables become painful. ADR-003. |
| State and routing | Keep Riverpod and go_router | GetX and Bloc would discard a structure that is already sound. get_it would be a second DI system next to Riverpod. | High if reversed later. ADR-004. |
| Errors in Dart | Sealed `Result<T>` in `core/` | fpdart is a fair library. We need one type, and Dart 3 already expresses it. | Low. ADR-005. |
| Immutable models | `freezed` and `json_serializable` when a model is touched | Hand-written `copyWith` already drifted (`isRead` is mutable). | Low. ADR-005. |
| Offline database | Drift (SQLite) | Isar's maintenance story is weaker. SQLite is boring and inspectable. | Medium. ADR-006. |
| Live location store | Realtime Database | Firestore document writes at a 5 second GPS rate are the expensive option. Booking documents stay in Firestore. | Medium. ADR-007. |
| Timers | Cloud Tasks for per-booking delays. Cloud Scheduler for sweeps | Pub/Sub does not wake a job at a chosen time. Cloud Functions were ruled out. | Medium. ADR-008. |
| Auth default | Firebase Auth phone OTP. FastAPI verifies the Firebase ID token | The team may still switch vendor. `AuthVerifier` is the seam. Custom JWT from the stub is not an auth system. | Medium. ADR-009. |
| Maps | Google Maps behind `MapsService` | Confirmed by the owner. The interface still allows a later swap. | Medium. ADR-010. |
| Payments | Cashfree behind `PaymentGateway` | Confirmed by the owner. Wallet and cash do not go through Cashfree. | Medium. ADR-010. |
| Repository layout | `git mv` to `app/`, `backend/`, `firebase/`, `docs/` in M00 | Renaming without `git mv` drops history. | Low. ADR-011. |
| API source of truth | FastAPI OpenAPI. Dart client generated in CI | Hand-written clients drift. | Medium to undo. ADR-012. |
| Who may write money and status | FastAPI only, via the Admin SDK | Client writes cannot be made idempotent or audited. | High. This is the golden rule. |

## Assumptions

| Topic | Default we will build | If this is wrong | Cost to change |
| --- | --- | --- | --- |
| Launch city | Patna, Bihar, India. Service area is a config polygon, not a `if (city == 'Patna')` | Another city | Config and seed data. Low. |
| Currency and tax | INR. GST 18% split into CGST 9% and SGST 9% for intra-state. Interstate IGST is out of MVP because we launch in one state. | A different rate | Config. Low. A different country is high. |
| Convenience fee | ₹49 on instant jobs, ₹0 on scheduled jobs, both config | No fee, or a percentage | Config. Low. |
| Mechanic share | 80% of labor. GST and parts are not part of the share. | Another split | Config, then a ledger migration if money already moved. Medium after launch. |
| Cancel fee | ₹0 before `enRoute`. ₹99 from `enRoute` until `arrived`. No self-serve cancel after `arrived`. | A different ladder | Config plus copy. Low before launch. |
| Offer timeout | 45 seconds. SOS 20 seconds. Two reassignments, then `failed`. | Faster or slower | Config. Low. |
| Location writes | Every 5 seconds while speed is above 5 km/h and status is `enRoute`. Every 15 seconds otherwise. Stop 2 minutes after `arrived`. | A different duty cycle | Config. Low. |
| Languages | English UI. Hindi in M16. Mechanic profile stores language codes the mechanic claims to speak. | Hindi required at launch | Move M16 strings earlier. Medium. |
| Phone numbers | Indian mobile, E.164 stored as `+91` plus 10 digits. Display masked except the last 4 for the other party. | Landlines | Validation change. Low. |
| Registration plates | Current Indian formats, validated, stored uppercased without spaces. | Vintage or diplomatic plates | Validator change. Low. |
| Devices | Android 7 (API 24) and iOS 15 and newer. Phones only. Portrait. | Tablets | Layout work. Medium. |
| Mechanic devices | Android is the priority. The same flavor builds for iOS. | Android-only forever | Drop the iOS flavor. Low. |
| Scheduled window | Customer picks a 60 minute window at least 90 minutes ahead and at most 7 days ahead. | Exact-time promises | Product copy and dispatch. Medium. |
| Extra work | Any new line that increases the estimate by more than ₹0 needs customer approval. A 10 minute timeout auto-rejects the extra and the mechanic continues with approved lines only. | Auto-approve under a cap | Rule change. Low. |
| Rewards | Show the existing loyalty point number as read-only if present. No earning rules in MVP. | A real points program | Phase 2. |
| Support phone | Config value. Demo may show the number already painted in the UI until M15. | | Config. Low. |
| Business hours | Instant booking 7:00–21:00 IST. SOS 24 hours. Outside hours the instant form explains the next open time and offers SOS or schedule. | 24 hour instant | Config. Low. |

## Open decisions (team-owned, already abstracted)

| Decision | Who | Default until they choose | What they edit |
| --- | --- | --- | --- |
| Final auth vendor | Teammate who owns identity | Firebase Auth phone | A new `AuthService` and `AuthVerifier` adapter, plus one binding |
| Firestore versus Supabase or Postgres as the system of record | Teammate who owns data | Firestore documents, Postgres mapping written so a move is possible | Repository adapters |
| SMS provider if auth is not Firebase's SMS | Teammate who owns auth | Firebase's phone SMS | `OtpSender` adapter inside auth |
| Push provider | Teammate who owns notifications | FCM | `NotificationSender` adapter |
| Cashfree account, keys, webhook URL | Owner supplies secrets | Fake gateway in dev | Env vars. No code change |
| Google Maps key | Owner supplies secrets | Fake maps in dev | Env and the Maps adapter config |
| Production GCP project and Firebase project | Owner | Emulator only until then | Env. Do not create projects from an agent session without asking |
| Application id `com.mechupp.app` | Owner | Application ID updated per ADR-016 | ADR-016 |

Do not block a milestone on an open decision. Build the fake adapter and the port. Ask the owner only when a secret, a bill, or a production deploy is required.
