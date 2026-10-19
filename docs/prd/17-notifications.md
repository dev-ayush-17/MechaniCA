# 17 — Notifications

Channels: **push** (FCM), **in-app** (notification document), **sms** (only if the flag is on and the push token is missing). Email is not a channel in MVP.

Deep links are go_router paths. The app opens the route if the user is signed in. If not, it stores the path for after login, for 15 minutes.

Templates use `{name}` placeholders. English copy is the MVP source. Hindi uses the same ids in M16.

## Matrix

| Event id | When | Recipient | Channels | Title | Body | Deep link |
| --- | --- | --- | --- | --- | --- | --- |
| `bookingConfirmed` | Status becomes `confirmed` | Customer | push, in-app | Booking confirmed | We're finding a mechanic for your {serviceName}. | `/booking/details?id={bookingId}` |
| `mechanicAssigned` | Accept | Customer | push, in-app, sms if no token | Mechanic assigned | {mechanicName} will reach you for {serviceName}. | `/tracking?id={bookingId}` |
| `offerCreated` | Offer opened | Mechanic | push, in-app | New job nearby | {serviceName}, {distanceKm} km, {totalRupees}. Tap to respond. | `/mechanic/offers/{offerId}` |
| `offerExpired` | This mechanic's offer expired | Mechanic | in-app | Offer ended | This job is no longer available. | `/mechanic/home` |
| `mechanicEnRoute` | `enRoute` | Customer | push, in-app | Mechanic is on the way | {mechanicName} has started towards you. | `/tracking?id={bookingId}` |
| `mechanicArrived` | `arrived` | Customer | push, in-app | Mechanic arrived | {mechanicName} has reached your location. | `/tracking?id={bookingId}` |
| `serviceStarted` | `inService` | Customer | push, in-app | Service started | Work has started on your {vehicleLabel}. | `/tracking/progress?id={bookingId}` |
| `extraWorkRequested` | Line pending | Customer | push, in-app | Approve extra work | {lineName} adds {amountRupees}. Approve or reject within 10 minutes. | `/booking/details?id={bookingId}` |
| `serviceCompleted` | `completed` | Customer | push, in-app | Service completed | Pay {totalRupees} to finish this booking. | `/invoice?id={bookingId}` |
| `paymentPaid` | `paid` | Customer | push, in-app, sms if no token | Payment successful | {totalRupees} paid for {displayNumber}. Your invoice is ready. | `/invoice?id={bookingId}` |
| `paymentPaid` | `paid` | Mechanic | push, in-app | Job paid | {displayNumber} is paid. Your recorded share is {shareRupees}. | `/mechanic/earnings` |
| `paymentFailed` | payment `failed` | Customer | push, in-app | Payment failed | The payment did not go through. You can try again. | `/booking/details?id={bookingId}` |
| `bookingCancelled` | `cancelled` | The other party | push, in-app | Booking cancelled | {displayNumber} was cancelled. | `/booking/details?id={bookingId}` |
| `bookingFailed` | `failed` | Customer | push, in-app | No mechanic available | We couldn't find a mechanic nearby. | `/booking/details?id={bookingId}` |
| `cashConfirm` | Mechanic marked cash | Customer | push, in-app | Confirm cash payment | Confirm you paid {totalRupees} in cash. | `/booking/details?id={bookingId}` |
| `reviewPrompt` | 1 hour after `paid` | Customer | push, in-app | Rate your service | How was {mechanicName}? | `/booking/details?id={bookingId}` |
| `verificationApproved` | Admin approves | Mechanic | push, in-app | You're verified | You can go online and take jobs. | `/mechanic/home` |
| `verificationRejected` | Admin rejects | Mechanic | push, in-app | Verification needs changes | {reason} | `/mechanic/onboarding` |
| `disputeOpened` | Dispute created | Support role | in-app | New dispute | {displayNumber} needs review. | `/admin/disputes/{disputeId}` |

Support in-app items are stored for every user with role `support` or `admin`. That is a small fan-out. Do it in the use case, not in a client loop.

## Rules

- Sending is the server's job after the state change commits. The client does not send its own "booking confirmed" push.
- A failed FCM send is logged and retried once. It does not roll back the booking.
- The user can disable marketing later. They cannot disable `paymentPaid`, `mechanicAssigned`, or `bookingFailed`. Those are transactional. The settings screen says so.
- Quiet hours are not applied to SOS or to payment events.
- Each send writes an audit-friendly log: template id, user id, channel, success. Not the full phone number.

## In-app list

The existing notifications screen is the UI. It reads `/v1` or a repository that listens to `users/{id}/notifications`. Mark-all-read sets `readAt` through the API in batches of 50, or via the allowed client field update. Prefer the API so both platforms share one path. Client rule update remains as a backup and must not be the only implementation if it complicates testing. **Decision:** mark-read goes through `POST /v1/notifications/{id}/read` so we do not special-case Security Rules. Chapter 10's client `readAt` exception is withdrawn. Rules deny all client writes to notifications. This is simpler and matches the golden rule.

Add that endpoint to the inventory in spirit: it is part of M09. Chapter 10's table said client may set `readAt`. This chapter overrides that. The implementation follows this chapter.

## Empty and error

- Empty: "No notifications yet."
- Push permission denied: banner on home, not a modal on every launch. "Turn on notifications to know when your mechanic is assigned."
- Token refresh: `POST /v1/me/devices` on each launch with the FCM token.
