# 25 — Glossary and appendices

## Glossary

| Term | Plain meaning |
| --- | --- |
| Adapter | The code that talks to one vendor or database. The rest of the app talks to a port instead. |
| Admin SDK | Firebase library that runs on the server and bypasses Security Rules. The phone does not use it. |
| ADR | Architecture Decision Record. A short note on a choice and why the other option lost. |
| Booking | One job: a customer, a vehicle, a service, a place, and a lifecycle. |
| Claim | A field inside the auth token, such as `role`. The server can set it. The phone should not be trusted to invent it. |
| Cloud Run | Google's service that runs the FastAPI container. |
| Cloud Tasks | A Google queue that calls an HTTP URL at a chosen time. We use it for "offer expires in 45 seconds." |
| Composition root | The one place that decides which adapter is used. `providers.dart` on the phone, `deps.py` on the server. |
| Convenience fee | A platform fee added to the bill. Default ₹49 for instant jobs. Config. |
| Coupon | A discount code with rules. The server decides if it applies. |
| DPDP | India's Digital Personal Data Protection Act. The checklist in chapter 16 is engineering work, not a legal opinion. |
| Drift | A SQLite library for Flutter. Our offline cache. |
| DTO | Data transfer object. The JSON shape. It is mapped into a domain entity before the UI uses it. |
| Emulator | A local fake of Firebase. Safe to wipe. Not production. |
| FCM | Firebase Cloud Messaging. Push notifications. |
| Freezed | A Dart package that generates immutable classes and `copyWith`. |
| Geohash | A short string that represents a map square, so we can query "mechanics near this square." |
| Golden rule | Clients read live data. Only FastAPI changes status, money, coupons, ratings, and verification. |
| GST / CGST / SGST | Indian tax. We assume 9% + 9% inside one state. |
| Idempotency key | A UUID the app sends so a retry does not create a second booking or a second charge. |
| Ledger | The list of wallet credits and debits. Balance is derived from it. |
| MoSCoW | Must, Should, Could, Won't. Priority labels. |
| OIDC | A signed Google token that Cloud Tasks uses to prove it is allowed to call our internal URL. |
| Paise | One hundredth of a rupee. We store money as paise integers so 0.1 + 0.2 cannot happen. |
| Port | An interface. `PaymentGateway` is a port. Cashfree is an adapter. |
| Result | A success value or a typed error. Used instead of throwing for expected failures. |
| RTDB | Firebase Realtime Database. We use it for live location, not for bookings. |
| Security Rules | Firebase's per-document permissions. They block client writes even if the app has a bug. |
| Snapshot | A copy of the vehicle, price, or mechanic stored on the booking so later edits do not rewrite history. |
| SOS | A breakdown request with faster, wider dispatch. |
| Webhook | Cashfree calling our server when a payment finishes. We verify the signature first. |

## Appendix A — Sample booking JSON

```json
{
  "id": "3f1c9a2b-1111-2222-3333-444455556666",
  "displayNumber": "MC3F1C9A2B",
  "customerId": "uid_customer",
  "vehicleSnapshot": {
    "vehicleType": "two_wheeler",
    "brand": "Hero",
    "model": "Splendor",
    "registrationNumber": "BR01AB1234"
  },
  "serviceCode": "general_service",
  "serviceNameSnapshot": "General Service",
  "mode": "instant",
  "urgency": "normal",
  "status": "enRoute",
  "addressSnapshot": {
    "label": "Home",
    "line1": "Boring Road",
    "city": "Patna",
    "pincode": "800001",
    "lat": 25.5941,
    "lng": 85.1376
  },
  "estimate": {
    "laborPaise": 59900,
    "partsPaise": 0,
    "feePaise": 4900,
    "discountPaise": 0,
    "cgstPaise": 5832,
    "sgstPaise": 5832,
    "totalPaise": 76464
  },
  "approvedTotalPaise": 76464,
  "paymentMethod": "upi",
  "mechanicSnapshot": {
    "displayName": "Imran",
    "ratingAvg": 4.8,
    "languages": ["hi", "en"],
    "verified": true
  },
  "version": 4
}
```

## Appendix B — Sample Security Rules (sketch)

Shipped as real files in M00 and extended later. This is the behavior, not a drop-in file.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function isSelf(uid) { return signedIn() && request.auth.uid == uid; }

    match /users/{uid} {
      allow read: if isSelf(uid);
      allow write: if false;
      match /vehicles/{id} {
        allow read: if isSelf(uid);
        allow write: if false;
      }
      match /notifications/{id} {
        allow read: if isSelf(uid);
        allow write: if false;
      }
    }

    match /bookings/{id} {
      allow read: if signedIn() && (
        resource.data.customerId == request.auth.uid ||
        resource.data.mechanicId == request.auth.uid
      );
      allow write: if false;
      match /messages/{mid} {
        allow read: if signedIn() && (
          get(/databases/$(database)/documents/bookings/$(id)).data.customerId == request.auth.uid ||
          get(/databases/$(database)/documents/bookings/$(id)).data.mechanicId == request.auth.uid
        );
        allow write: if false;
      }
    }

    match /payments/{id} { allow read, write: if false; }
    match /coupons/{id} { allow read, write: if false; }
    match /auditLog/{id} { allow read, write: if false; }
    match /serviceCatalog/{code} {
      allow read: if signedIn();
      allow write: if false;
    }
  }
}
```

RTDB sketch:

```
{
  "rules": {
    "liveLocations": {
      "$bookingId": {
        ".read": "auth != null && (root.child('bookingGates').child($bookingId).child('customerId').val() == auth.uid || root.child('bookingGates').child($bookingId).child('mechanicId').val() == auth.uid)",
        "mechanic": {
          ".write": "auth != null && root.child('bookingGates').child($bookingId).child('mechanicId').val() == auth.uid && root.child('bookingGates').child($bookingId).child('locationOpen').val() == true"
        },
        "customer": {
          ".write": "auth != null && root.child('bookingGates').child($bookingId).child('customerId').val() == auth.uid && root.child('bookingGates').child($bookingId).child('locationOpen').val() == true"
        }
      }
    }
  }
}
```

`bookingGates` is maintained only by the Admin SDK. Clients do not write it. In RTDB rules, `root` reads RTDB, so the gate mirror for rules lives in RTDB and is written by the API. Firestore remains the system of record. The API updates both.

## Appendix C — Sample port (Dart shape, illustrative)

M00 and feature milestones write the real files. This shows the expected style.

```dart
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}

abstract interface class BookingRepository {
  Future<Result<Booking>> insert(Booking draft);
  Future<Result<Booking>> update(Booking next, int expectedVersion);
}
```

Python uses a `Protocol` with the same method names and raises `Conflict`, `InvalidInput`, and the other errors from chapter 08.

## Appendix D — Screen to feature to milestone

| Current route | Milestone that changes behavior | Notes |
| --- | --- | --- |
| Splash, onboarding, login, OTP | M02 | Delete forgot-password route |
| Home | M14 | M01 only if a shared widget must move |
| Bikes | M03 | Domain name Vehicle. Route may stay `/bikes` |
| Booking wizard | M05, M06 | Pricing, then the new state machine |
| Tracking | M08 | Replace the fake timeline |
| Emergency | M06, M07 | SOS flag and priority dispatch |
| Inspection | M13 | Customer view of parts photos |
| Invoice | M11 | By booking id, PDF |
| Wallet, offers | M10 | |
| History, profile, addresses | M14 | |
| Notifications | M09 | |
| Support FAQ | Stays local | Tickets become disputes in M15 |
| Fuel, membership, refer, documents | None | Must still open |
| Health | M14 | Honest placeholder score |
| Mechanic and admin routes | M04, M15 | Do not exist yet |

## Appendix E — Requirement index

Auth: FR-AUTH-001–005. Booking: FR-BOOK-001–009. Tracking: FR-TRK-001–007. Comms: FR-COM-001–004. Vehicles: FR-VEH-001–006. Pay: FR-PAY-001–010. Invoice: FR-INV-001–002. Mechanic: FR-MEC-001–008. Reviews: FR-REV-001–004. Notifications: FR-NOT-001–004. User: FR-USR-001–009. Admin: FR-ADM-001–009.

NFR prefixes: PERF, SCALE, AVAIL, OFF, A11Y, I18N, DEV, BAT, SEC, MAIN, LOG. Defined in chapter 06.
