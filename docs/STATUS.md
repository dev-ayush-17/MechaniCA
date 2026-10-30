# MechUpp — team status (21 Oct 2026)

**Source of truth:** `origin/main` `873287c` (M16, [PR #25](https://github.com/dev-ayush-17/MechaniCA/pull/25)).

The phone demo using fakes does **not** mean the backend is empty. **M00–M16 are implemented.** What you see without Firebase is the **in-memory demo**, on purpose. Production is **not** a second app; it is plugging the same API into live vendors.

| | |
| --- | --- |
| Product spec (M00–M16) | **Done** |
| FastAPI domain + HTTP + tests | **Done** (runs locally with fakes) |
| Live India stack (Firebase, Cloud Run, Cashfree, Maps, Play) | **Not live** |
| Leftover vs work already done | ~**15–25%** more |

---

## Backend — what is already built

`backend/` is a real FastAPI service (Python 3.12), not a UI mock.

- **Contract:** OpenAPI from FastAPI; Dart client is generated. CI checks it stays current.
- **Rules already in code:** only the API writes booking status, prices, payments, wallet, coupons, invoices, verification. Money is **integer paise**. Booking/payment create need an **Idempotency-Key**. Phone SDK “success” does **not** mark paid — webhook/reconcile does.
- **Use cases shipped:** bootstrap user, vehicles, catalog/quotes, idempotent booking + cancel/transitions/extra lines, dispatch + offer timeouts, tracking links, chat + rate limit, Cashfree/cash/wallet/coupons, GST invoice PDF, parts/reviews, admin (search, suspend, disputes, revenue, coupons, audit), HTTP rate limits, CORS allow-list.
- **How it runs today:** composition root `deps.py` binds **fake** adapters (process memory). Restart = data gone. That is the demo, not a missing API.

**Already have a real adapter file (flip env when secrets exist):** Firebase Auth, Firestore bookings/catalog/vehicles/chat/notifications, RTDB location, FCM, Cashfree, Google Maps, Cloud Tasks.

**Still fake-only (must be written against Firestore/Storage once the project exists):** users, addresses, payment/wallet/coupon stores, invoices, disputes, reviews/parts, mechanics, file storage, audit, some offer/link stores.

CI: `ruff`, `mypy`, `pytest` (~140 tests), import-boundary + secret scan.

---

## What is stopping a **live** backend

Not “no backend.” These are the gates:

1. **No production/staging Firebase or GCP project** — no Auth SMS, no Firestore, no RTDB, no Storage. FastAPI has nowhere durable to save.
2. **Fake providers are the default** (`PROVIDER_AUTH=fake`, etc.). Live needs env + Admin SDK on Cloud Run (not a key file in git).
3. **API is not deployed** — local `uvicorn` / emulator only. Prod target is **Cloud Run `asia-south1`**.
4. **Cashfree + Maps** are separate from Firebase. Without those accounts, pay and map stay fake even if Firebase is up.
5. **Remaining Firestore adapters** (list above) — bookings can go live before every collection, but a full product path needs those stores.

Until (1)+(2), the app correctly looks “empty” on a real phone: `API_BASE_URL` in the debug APK is `10.0.2.2` (emulator host), and fakes do not survive process restart.

---

## After Firebase credentials — small or large?

**Small-to-medium. Not a rewrite.**

| After you have a Firebase project + billing (Blaze) | Size |
| --- | --- |
| Point Auth / existing Firestore & RTDB adapters at the project, emulator then staging | **Small** (config + smoke) |
| Write the **missing** Firestore/Storage adapters and tests | **Medium** (~1–3 weeks focused), same ports, no new domain |
| Cashfree webhook URL + Maps key + Cloud Run min-1 | **Ops**, not product code |
| Play listing, upload keystore, privacy URL | **Owner**, not backend |

Firebase creds **do** unlock persistence and real OTP. They **do not** finish Cashfree, Maps, or Play.

---

## App — what it can do today (demo)

Customer / mechanic / admin-web in one package. Dev OTP **`123456`**. Walk booking, SOS, tracking (placeholder map), pay → “waiting for confirmation”, invoice PDF, chat, admin ≥1024px.

Debug APK: `Aethenox-m16/mechupp-demo-debug.apk` (debug-signed — not for Play).

---

## Future / not this MVP

Fuel, membership, referral, documents APIs; Play Integrity; masked calling in prod. Issues #26, #27.

**Play path:** Blaze + Cloud Run → bind adapters → sandbox Cashfree → release AAB `com.mechupp.app` → internal test. Do not ship sandbox keys or demo OTP.

Cost (small): Cloud Run min-1 ~$20–80/mo idle; SMS + Maps dominate; FCM free. See [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
