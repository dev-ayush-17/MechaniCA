# 018 — Free walkthrough: accept gate, Firestore offers, two APKs

The customer app could show a mechanic who never tapped Accept, because offers
lived in process memory and the details screen fell back to mock bookings.
Create still lands on `confirmed` (“Finding a mechanic”). `mechanicAssigned`
is written only in `SequentialDispatch.accept`.

**Dispatch timing** stays at the spec defaults in code: offer TTL 45 seconds,
and an empty candidate list fails immediately (`wait_for_mechanic_seconds=0`).
The local demo `.env` may raise the TTL and the wait, and turn on a sweep, so
one phone can submit as the customer and then open the mechanic app. Tests
keep the defaults.

**Persistence.** `MECHUPP_PROVIDER_MECHANICS` and `MECHUPP_PROVIDER_OFFERS` bind
Firestore adapters in `deps.py` only. Seeded mechanics are real user documents
plus `mechanics/{uid}`. After an API restart, a fake OTP whose user document
role is mechanic is treated as that mechanic. Pytest skips that lookup.

**Pay (demo).** `MECHUPP_DEMO_WALLET_FLOAT` (dev and test only) credits the
shortfall and then debits the wallet. The phone does not mark a booking paid.
Cashfree, Maps, and SMS stay fake.

**Two apps on one phone.** Product flavors `customer` (`com.mechupp.app`) and
`mechanic` (`com.mechupp.mechanic`). `flutter run` needs `--flavor`.

Rollback: set mechanics, offers, and catalog providers back to `fake`, set the
dispatch overrides and `DEMO_WALLET_FLOAT` off, and install a single flavor.
