# ADR-009 — Firebase Auth phone OTP is the default

**Status:** accepted. **Date:** 2026-10-19.

The team has not signed a final auth vendor. The demo's `POST /login` returns a fake JWT.

**Decision:** `AuthService` on the client and `AuthVerifier` on the server. The first real adapter is Firebase Auth phone OTP. FastAPI accepts Firebase ID tokens. Roles are custom claims written by the Admin SDK. Google is a later adapter behind a flag, default off. There is no MechaniCA-issued JWT in the MVP.

**Why this and not the alternatives:** Waiting for a vendor decision blocks M02. Building our own OTP stack means storing codes and sending SMS before we have a sender. The port still lets a teammate replace Firebase Auth later.

**Consequences:** Our user id equals the Firebase uid until a migration. The user document also stores `authProvider` and `authSubject`. M00 deletes the fake login endpoint.
