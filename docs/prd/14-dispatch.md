# 14 — Dispatch and matching

Dispatch picks a mechanic for a `confirmed` booking. It does not set prices and it does not talk to Cashfree.

## When it runs

| Mode | Start |
| --- | --- |
| Instant, inside hours or SOS | Immediately after `confirmed` |
| Instant, outside 07:00–21:00, not SOS | Booking is `failed` with `outside_hours` before dispatch. The API never confirms it |
| Scheduled | Cloud Task at `scheduledStart - 60 minutes` |
| Reassignment | Immediately after the previous offer ends without an accept, if attempts remain |

## Candidate query

1. Load mechanics with `verified=true`, `online=true`, `lastHeartbeatAt` within 2 minutes.
2. Geohash precision 6 of the job point, plus the 8 neighboring cells.
3. Drop anyone farther than the radius.
4. Drop anyone who already rejected or timed out on this booking.
5. Drop anyone with a booking in `mechanicAssigned`, `enRoute`, `arrived`, or `inService`. One active job per mechanic in MVP.

| Urgency | First radius | Second radius | Third |
| --- | --- | --- | --- |
| normal | 5 km | 8 km | 12 km |
| sos | 8 km | 15 km | 25 km |

If a radius returns nobody, expand. Do not expand past the third ring. Then fail the booking.

## Ranking

Score each candidate, higher is better. Weights are config.

```
score = (ratingAvg * 20) + (acceptanceRate * 30) - (distanceKm * 8) - (recentOffers * 5)
```

- `ratingAvg` defaults to 4.5 when `ratingCount` is under 5, so new mechanics are not stuck at zero. The profile shows "New" instead of a fake precise score until 5 reviews.
- `acceptanceRate` is accepts / (accepts + rejects + timeouts) over the last 30 days, default 0.8 when the sample is under 10.
- `recentOffers` is offers in the last 30 minutes, so one mechanic does not get every job.
- SOS adds `+15` to anyone inside 3 km and ignores rating below that distance. Closer wins.

Take the top 1. We do not fan out one job to five mechanics in MVP. Fan-out creates double accepts and a worse customer story. Sequential offers are easier to explain and to make correct.

## Offer

Create an offer document: `bookingId`, `mechanicId`, `status=open`, `expiresAt`, `attempt` (1-based).

Notify the mechanic (push and in-app): service name, distance, total estimate, vehicle type, seconds left.

Schedule a Cloud Task at `expiresAt`.

| Urgency | TTL |
| --- | --- |
| normal | 45 seconds |
| sos | 20 seconds |

## Outcomes

| Event | Result |
| --- | --- |
| Accept before expiry | Transaction: offer `accepted`, booking `mechanicAssigned`, other work cancelled. Loser gets `offer_gone` |
| Reject | Offer `rejected`. Start next attempt |
| Task fires and offer still `open` | Offer `expired`. Start next attempt |
| Attempt would become 4 | Booking `failed`, reason `no_mechanic`, notify customer |
| Mechanic heartbeat dies after assign and before `enRoute` for 10 minutes | Treat as a reject and reassign if attempts remain |

Attempts count offers, not radius expansions. Radius expansion happens inside one attempt while building the candidate list.

## Customer copy during dispatch

| Situation | Text |
| --- | --- |
| Attempt 1 running | "Finding a mechanic near you" |
| Later attempt | "Still looking. The first mechanic was unavailable." |
| Failed | "No mechanic is free nearby. Try again or contact support." |
| SOS failed | "No mechanic could take the priority request. If this is an emergency, call 112." |

The countdown on the mechanic phone is cosmetic. The server task is the decision.

## Fairness and safety

- Do not include gender, religion, or caste anywhere in the score. The profile does not collect them.
- Do not dispatch a suspended mechanic.
- A mechanic outside their declared service area is excluded even if the geohash matched. The circle is the contract they signed up for.
- Admin can see the attempt list on the booking timeline: who was offered, the score, and the outcome. That timeline is an audit event per attempt.

## Failure to place the task

If Cloud Tasks returns an error while creating the timeout, the API still saves the offer and a Scheduler sweep every minute expires offers with `expiresAt` in the past. The task is an optimization. The sweep is the safety net. Both call the same use case.
