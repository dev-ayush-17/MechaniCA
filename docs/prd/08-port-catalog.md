# 08 — Port catalog

Ports are interfaces. **Core** means the milestone that introduces the feature must add the port and a fake adapter before the real one. **Deferred** means the signature is reserved here and no code is written until that milestone. M00 only codes `Clock`, `Logger`, `FeatureFlags`, and `Result`.

Signatures are language-neutral. Dart uses `Future` and a sealed `Result`. Python uses `async` and raises the typed error, which the API layer maps to HTTP. The same names are used in both places.

Shared errors:

| Error | Meaning |
| --- | --- |
| `NotFound` | Id does not exist or is not visible to this actor |
| `PermissionDenied` | Actor is real but not allowed |
| `InvalidInput` | Field validation failed. Carries a map of field to message |
| `Conflict` | Illegal state transition, idempotency clash, duplicate |
| `Unavailable` | Downstream timeout or outage |
| `Unauthenticated` | Missing or bad token |

Money is integer paise inside the domain (`59900` = ₹599.00). APIs may show rupees in JSON as integers of paise to avoid float errors. Display formats rupees.

---

## Clock (Core, M00)

```
now(): Instant   # UTC
```

Fake clock is settable. No errors.

## Logger (Core, M00)

```
info(message, fields)
warning(message, fields)
error(message, fields, error?)
```

`fields` is string keys to scalars. The logger drops keys named `otp`, `token`, `authorization`, `card`, `secret`.

## FeatureFlags (Core, M00)

```
isEnabled(name: String, userId?: String): Bool
```

Source is environment, overridden by a fetched map in later milestones. Unknown flags are false.

## AuthService (Core, M02) — client

```
requestOtp(phoneE164): Result<Void>
verifyOtp(phoneE164, code): Result<Session>
signInWithGoogle(): Result<Session>          # adapter may be unimplemented
signOut(): Result<Void>
currentSession(): Session?                   # local
```

Errors: `InvalidInput`, `Unauthenticated`, `Unavailable`, plus `RateLimited`.

`Session` has `userId`, `idToken`, `expiresAt`, `role`.

## AuthVerifier (Core, M02) — server

```
verify(idToken: String): Result<Principal>
```

`Principal` has `userId`, `role`, `verified` (mechanics), `sessionId`.

Errors: `Unauthenticated` if expired, revoked, or the wrong project.

## UserRepository (Core, M02)

```
get(userId): Result<User?>
upsert(user): Result<User>
suspend(userId, reason, actorId): Result<User>
```

## VehicleRepository (Core, M03)

```
listByOwner(ownerId): Result<List<Vehicle>>
get(vehicleId, ownerId): Result<Vehicle?>
save(vehicle): Result<Vehicle>
delete(vehicleId, ownerId): Result<Void>
```

## MechanicRepository (Core, M04)

```
get(mechanicId): Result<Mechanic?>
saveProfile(mechanic): Result<Mechanic>
setVerification(mechanicId, status, reason, actorId): Result<Mechanic>
setAvailability(mechanicId, online): Result<Mechanic>
findOnlineNear(center, radiusKm, limit): Result<List<MechanicCandidate>>
```

`findOnlineNear` is the geo query. The Firestore adapter uses geohash. A Postgres adapter would use earth-distance. Callers do not know which.

## CatalogRepository and PricingService (Core, M05)

```
listActiveServices(): Result<List<ServiceDefinition>>
getService(code): Result<ServiceDefinition?>

quote(input: QuoteInput): Result<PriceQuote>
```

`PricingService` is pure. It does not fetch. The use case loads the catalog, the coupon, and the vehicle, then calls `quote`.

## BookingRepository (Core, M06)

```
get(bookingId): Result<Booking?>
listForCustomer(customerId, filter): Result<Page<Booking>>
listForMechanic(mechanicId, filter): Result<Page<Booking>>
insert(booking): Result<Booking>
update(booking, expectedVersion): Result<Booking>
```

`expectedVersion` is optimistic concurrency. A mismatch is `Conflict`.

## DispatchService (Core, M07)

```
offer(bookingId): Result<Offer>
accept(offerId, mechanicId): Result<Booking>
reject(offerId, mechanicId): Result<Void>
expire(offerId): Result<Void>
```

Implemented as application code plus repositories, not as a vendor SDK. The interface exists so tests replace the whole policy.

## JobScheduler (Core, M07)

```
schedule(job: ScheduledJob): Result<Void>
cancel(jobId): Result<Void>
```

`ScheduledJob` has `id`, `runAt`, `targetPath`, `body`. The Cloud Tasks adapter creates an HTTP task with OIDC. The fake adapter stores jobs in memory and a test helper runs due jobs.

## LocationTrackingService (Core, M08)

```
publish(bookingId, role, point): Result<Void>
latest(bookingId): Result<LocationSnapshot?>
```

`point` has lat, lng, accuracyM, recordedAt, speedMps optional.

## MapsService (Core, M08)

```
geocode(address: String): Result<GeoPoint>
reverseGeocode(point): Result<String>
route(origin, destination): Result<RouteSummary>
```

`RouteSummary` has distanceM, durationS, encodedPolyline. Errors: `Unavailable`, `NotFound` if the address cannot be geocoded.

## ChatService (Core, M12)

```
send(bookingId, senderId, body): Result<ChatMessage>
list(bookingId, after?: Instant): Result<List<ChatMessage>>
```

Client reads may use a Firestore listener inside the adapter. The port stays request/response so tests are simple. The UI adapter may expose a stream wrapper. That wrapper is not a second source of truth.

## TelephonyPort (Core contract, M12)

```
mask(bookingId, partyA, partyB): Result<MaskedCall>
```

`MaskedCall` has `dialNumber`, `expiresAt`. If the flag is off, the use case does not call the port.

## PaymentGateway (Core, M10)

```
createOrder(order: PaymentOrder): Result<GatewayOrder>
verifyWebhook(headers, rawBody): Result<GatewayEvent>
refund(paymentId, amountPaise, idempotencyKey): Result<Refund>
fetch(gatewayOrderId): Result<GatewayOrder>
```

`verifyWebhook` returns `Unauthenticated` on a bad signature and does not parse a partial success.

## PaymentRepository (Core, M10)

```
get(paymentId): Result<Payment?>
insert(payment): Result<Payment>
applyEvent(paymentId, event, expectedVersion): Result<Payment>
```

## WalletService (Core, M10)

```
balance(userId): Result<Money>
credit(userId, entry): Result<LedgerEntry>
debit(userId, entry): Result<LedgerEntry>
```

`debit` returns `Conflict` with code `insufficient_wallet` when the balance would go negative. Entries are append-only.

## CouponService (Core, M10)

```
validate(code, context): Result<CouponQuote>
redeem(code, bookingId, context): Result<CouponQuote>
```

`validate` does not increment counters. `redeem` does, once, keyed by booking id.

## InvoiceService (Core, M11)

```
render(bookingId): Result<InvoiceFile>
get(bookingId): Result<InvoiceFile?>
```

## FileStorage (Core, M04)

```
signedUpload(path, contentType, maxBytes): Result<SignedUpload>
signedDownload(path): Result<Url>
```

The adapter writes metadata. Callers choose the path from the rules in the feature spec, not from user input alone. Reject paths that contain `..`.

## ReviewRepository (Core, M13)

```
save(review): Result<Review>
listForMechanic(mechanicId): Result<Page<Review>>
recomputeAggregate(mechanicId): Result<RatingAggregate>
```

## NotificationSender (Core, M09)

```
send(message: OutboundNotification): Result<Void>
```

`OutboundNotification` has `userId`, `channel` (`push`, `inApp`, `sms`), `templateId`, `data`, `deepLink`. The use case looks up the matrix and calls `send` once per channel. In-app is a repository write. Push is FCM. SMS is optional.

## AnalyticsService (Deferred code, M15; port defined now)

```
track(name, properties): Result<Void>
```

Properties must be on the allow-list in chapter 18. The M00 logger can implement this until M15.

## DisputeRepository (Core, M15)

```
open(dispute): Result<Dispute>
addNote(disputeId, note, actorId): Result<Dispute>
resolve(disputeId, resolution, actorId): Result<Dispute>
```

## AuditLog (Core, M04)

```
append(event: AuditEvent): Result<Void>
list(target): Result<List<AuditEvent>>
```

No update and no delete methods.

## Deferred until Phase 2 (no milestone code)

| Port | Why it waits |
| --- | --- |
| `MembershipService` | Membership screens stay demo-only |
| `ReferralService` | No payout rules |
| `FuelLogRepository` | Fuel screen stays demo-only |
| `DocumentVaultRepository` | RC/insurance vault is Phase 2 |
| `PayoutService` | Bank payout to mechanics is Phase 2 |
| `EmailSender` | No email account flow |

Do not create empty interfaces for these "so we are ready." The catalog above is the ready. Code lands with the feature.
