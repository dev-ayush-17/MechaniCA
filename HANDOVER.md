# MechUpp — Developer Handover Guide

## What this is
MechUpp is an on-demand mechanic booking app for two-wheelers in India.
This repo contains a **working demo build** ready for Play Store Internal
Testing and further development.

---

## Repository
- **GitHub**: https://github.com/dev-ayush-17/MechaniCA
- **Collaborator remote**: https://github.com/saurabhKumar9060/Mechanika-app
- **Default branch**: main (this build)

---

## App Summary

| Area | Status |
|---|---|
| Firebase Phone OTP login | ✅ Working |
| Booking creation + dispatch | ✅ Working (auto-accept enabled in staging) |
| Live tracking screen | ✅ Working (custom map placeholder, no Maps key needed) |
| Chat | ✅ Working |
| Mechanic app shell | ✅ Working (auto-accept handles bookings) |
| Payments (Cashfree) | ⏳ Coming Soon banner shown — Cashfree keys pending |
| Add Money (wallet) | ⏳ Coming Soon banner shown — Cashfree keys pending |
| Real-time Maps (Google Maps SDK) | ⏳ Placeholder only — Maps key pending |

---

## What you need to run locally

### 1. Flutter App

`ash
cd app
flutter pub get
flutter run --flavor customer -t lib/main.dart           # customer app
flutter run --flavor mechanic -t lib/main_mechanic.dart  # mechanic app
`

- Requires Flutter 3.x (stable channel)
- pp/config/cloud.json has the staging Firebase config already

### 2. Backend (FastAPI)

`ash
cd backend
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # Linux/Mac
pip install -e ".[dev]"
cp .env.example .env            # then fill in real values
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
`

**Required .env values for staging:**
`
MECHUPP_APP_ENV=staging
MECHUPP_PROVIDER_AUTH=firebase
MECHUPP_PROVIDER_USERS=firebase
MECHUPP_PROVIDER_BOOKINGS=firestore
MECHUPP_PROVIDER_MECHANICS=firestore
MECHUPP_FIREBASE_PROJECT_ID=mechupp-staging
MECHUPP_FIREBASE_DATABASE_URL=https://mechupp-staging-default-rtdb.firebaseio.com
MECHUPP_FIREBASE_CREDENTIALS=serviceAccount.json
MECHUPP_DISPATCH_AUTO_ACCEPT=true
MECHUPP_DISPATCH_AUTO_ACCEPT_FALLBACK_MECHANIC_ID=rLbLmYXRgaVV9X7KIQvZQR0hXQ62
`

The Firebase service-account JSON (mechupp-staging-firebase-adminsdk-*.json) is in
ackend/ — rename it to serviceAccount.json or set MECHUPP_FIREBASE_CREDENTIALS
to the exact filename.

### 3. Docker (backend only)

`ash
# Build and start the backend API
docker compose up --build

# Server starts at http://localhost:8080
# Swagger docs at http://localhost:8080/docs
`

Requires:
- ackend/.env (copy from .env.example and fill)
- ackend/serviceAccount.json (Firebase admin key)

---

## APK Files

Pre-built APKs are in the repo root:
- mechupp-customer.apk — Customer app (debug-signed release)
- mechupp-mechanic.apk — Mechanic app (debug-signed release)

To install:
`ash
adb install mechupp-customer.apk
`
Or share via Google Drive / WhatsApp and install with "Install unknown apps" enabled.

To build fresh:
`ash
cd app
flutter build apk --flavor customer --release -t lib/main.dart
# Output: build/app/outputs/flutter-apk/app-customer-release.apk
`

---

## Play Store Checklist (Internal Testing track)

- [ ] Privacy Policy URL (required even for internal)
- [ ] Data Safety form: declares phone number + location
- [ ] At least 2 phone screenshots
- [ ] App description
- [ ] Target SDK ≥ 34 (already set in build.gradle via flutter.targetSdkVersion)
- [ ] Signed with a **release keystore** (current APKs use debug signing — fine for internal testing but not production)

---

## What's Pending for Production Launch

1. **Cashfree integration**: Add MECHUPP_CASHFREE_APP_ID + MECHUPP_CASHFREE_SECRET
   to backend .env. In Flutter, bind the Cashfree Flutter SDK in
   pp/lib/composition/providers.dart → paymentCheckoutProvider.

2. **Google Maps API key**:
   - Backend: MECHUPP_GOOGLE_MAPS_SERVER_KEY
   - Android: Add to pp/android/app/src/main/AndroidManifest.xml meta-data
   - Replace _MapPlaceholder widget in live_tracking_screen.dart with
     actual google_maps_flutter widget.

3. **Mechanic verification**: Backend mechanic approval flow and
   MECHUPP_DISPATCH_AUTO_ACCEPT=false once real mechanics are onboarded.

4. **Release keystore**: Generate and store safely. Update uild.gradle.kts
   signingConfigs block.

5. **FCM push**: Already wired in app; set up FCM server key in Firebase console.

---

## Key Docs

| File | What it says |
|---|---|
| AGENTS.md | Architecture rules |
| docs/PRD.md | Full product spec |
| docs/MILESTONES.md | Feature build order |
| docs/STATUS.md | Current status of every milestone |
| docs/AGENT_PROGRESS.md | Last session stop point |

---

## Running Checks

`ash
# Flutter
cd app && flutter analyze && flutter test

# Backend
cd backend && ruff check . && mypy app && pytest -q

# Import boundary check
python tool/check_import_boundaries.py
`

All pass on main as of this handover.
