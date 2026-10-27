# 017 — Spark demo: fake OTP, live FastAPI and Firestore

Phone SMS OTP needs a Blaze plan. Until then the app keeps `PROVIDER_AUTH=fake`
(demo code `123456`) and sets `USE_HTTP_API=true` so vehicles, bookings, and
profile go through FastAPI. FastAPI uses the Admin SDK against `mechupp-staging`.

Client Firebase Auth, FCM, and RTDB wait on `google-services.json` plus Blaze.
Cashfree and Google Maps stay fake until those keys exist.

Rollback: `USE_HTTP_API=false` and all `MECHUPP_PROVIDER_*=fake`.
