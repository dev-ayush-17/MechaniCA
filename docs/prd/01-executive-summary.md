# 01 — Executive summary

## Vision

A vehicle owner in India can get a verified mechanic to their location, watch them arrive, approve the work, pay, and keep the invoice, without handing the vehicle to an unknown workshop.

MechaniCA's MVP is that loop for two-wheelers and four-wheelers in one launch city. The demo city in the current app is Patna. The city is configuration, not a hardcoded assumption in business code. See [assumptions](04-assumptions.md).

## Problem

Roadside and doorstep repair is mostly informal. Owners cannot see who is coming, what the price will be, or whether a replaced part was actually replaced. Mechanics have no reliable job stream, and the platform has no audit trail when a customer disputes a bill.

## What ships in the MVP

Three entrypoints, one Flutter codebase, one FastAPI service:

| Entrypoint | Who | MVP outcome |
| --- | --- | --- |
| Customer app (iOS and Android) | Vehicle owner | Book, track, chat, pay, invoice, history |
| Mechanic app (Android first, iOS same codebase) | Verified mechanic | Go online, accept a job, navigate, update status, upload parts photos, see earnings |
| Admin (Flutter web) | Staff | Verify mechanics, inspect orders, coupons, disputes, revenue |

Trusted changes go through FastAPI. Live location and chat streams are read from Firebase. Details are in [architecture](07-system-architecture.md) and [hybrid backend](10-hybrid-backend.md).

## Goals

1. A customer can complete an instant booking in under 2 minutes on a 4G connection when they already have an account and a saved vehicle.
2. A mechanic inside the service area is offered the job within 15 seconds of confirmation, and either accepts or the offer expires in 45 seconds.
3. The customer can see mechanic location updated at least every 15 seconds while the mechanic is en route, with a visible stale state after 60 seconds.
4. Every completed job can be paid by UPI, card or netbanking (via Cashfree), cash, or wallet, and produces a downloadable GST invoice.
5. A parts replacement has before, after, and old-part photos tied to the line item, visible to the customer, and immutable after upload.
6. The demo keeps working on fake adapters until each feature is switched to the real adapter.

## Non-goals for MVP

- Pickup-to-workshop and "visit workshop" fulfillment. The current demo models this. The product does not. It is Phase 2.
- Fuel logs, membership subscriptions, referral payouts, and a document vault (RC, insurance, PUC). The screens stay in the demo so it does not break. They do not get a backend.
- A native admin app, a separate React admin, or Cloud Functions.
- Storing or transmitting raw card numbers. Cashfree's client SDK and hosted checkout do that.
- Multi-country, multi-currency, or more than one live city in production configuration.
- Hindi copy. The string system is ready in M01. Hindi translations land in M16.
- Email/password accounts. Phone OTP is the default. Google is a later adapter. The Google button may remain visible but disabled until that adapter exists.

## Success metrics (first 90 days after launch)

| KPI | Target | How it is measured |
| --- | --- | --- |
| Time to submit instant booking | Median under 120 seconds from "Book" to `201` | Client analytics `booking_submitted` minus `booking_started` |
| Time to first mechanic offer | p95 under 15 seconds after `confirmed` | Server log on dispatch start |
| Assignment success | At least 80% of confirmed instant jobs reach `mechanicAssigned` | Booking status counts |
| Tracking freshness | At least 95% of en-route sessions have a location younger than 60 seconds | RTDB timestamp vs server clock |
| Payment success | At least 95% of attempted online payments reach `paid` or a reconciled `failed` within 15 minutes | Payment records, excluding user-cancelled |
| Cash confirmation | At least 98% of cash jobs reach `paid` or `disputed` within 24 hours | Payment records |
| Dispute rate | Under 3% of paid jobs opened as disputes within 7 days | Dispute records |
| Crash-free sessions | At least 99.5% | Crash reporting (adapter; vendor chosen in M16) |
| Invoice download | At least 99% of `paid` jobs have a stored PDF within 2 minutes of payment | Invoice records |
| Mechanic verification SLA | 90% of complete applications decided within 2 business days | Verification timestamps |

These are targets, not promises to users. Missing a target is an incident or a backlog item, not a silent change to the requirement.

## Users

See [personas](02-personas-and-journeys.md). The short version: a customer who owns one or more vehicles, a mechanic who works a service area, a support agent who handles disputes, and an admin who verifies mechanics and manages coupons.

## How to read the rest

If you are new to the codebase, read [learning notes](../LEARNING_NOTES.md), then this chapter, then the [audit](03-frontend-audit.md). If you are implementing a milestone, read that milestone file and only the chapters it links.
