# MechUpp — Product and architecture specification

MechUpp is an on-demand mechanic and roadside-assistance product for two-wheeler and four-wheeler owners in India. A customer books a verified mechanic who comes to their location, can be tracked live, gets the work done, pays, and downloads a GST invoice.

This file is the index. The detail lives in the chapters below so a single session can update one area without rewriting the whole spec.

**Status:** Phase 0 (specification). No production backend exists. The Flutter demo is mock data.

**Read next:** [Learning notes](LEARNING_NOTES.md) for a plain-English walkthrough, [Milestones](MILESTONES.md) for build order, [Agent progress](AGENT_PROGRESS.md) for where work stopped.

## Chapters

| # | Chapter | What it decides |
| --- | --- | --- |
| 01 | [Executive summary](prd/01-executive-summary.md) | Vision, goals, non-goals, KPIs |
| 02 | [Personas and journeys](prd/02-personas-and-journeys.md) | Customer, mechanic, admin, support |
| 03 | [Frontend audit](prd/03-frontend-audit.md) | What the demo is, what to keep, what to rewrite |
| 04 | [Assumptions and open decisions](prd/04-assumptions.md) | Defaults and what it costs to change them |
| 05 | [Functional requirements](prd/05-functional-requirements.md) | `FR-*` stories and acceptance criteria |
| 06 | [Non-functional requirements](prd/06-non-functional-requirements.md) | Speed, offline, accessibility, devices |
| 07 | [System architecture](prd/07-system-architecture.md) | Layers, folders, provider swap matrix |
| 08 | [Port catalog](prd/08-port-catalog.md) | Interfaces, Core vs Deferred |
| 09 | [Domain and data model](prd/09-domain-and-data-model.md) | Entities, Firestore, Postgres mapping |
| 10 | [Hybrid backend](prd/10-hybrid-backend.md) | Who may write what, endpoints, timers |
| 11 | [Authentication](prd/11-authentication.md) | Phone OTP, roles, swapping providers |
| 12 | [API contracts](prd/12-api-contracts.md) | Errors, versioning, idempotency |
| 13 | [State machines](prd/13-state-machines.md) | Booking, payment, availability, verification |
| 14 | [Dispatch and matching](prd/14-dispatch.md) | Geo query, ranking, timeouts |
| 15 | [Payments](prd/15-payments.md) | Cashfree, cash, wallet, refunds |
| 16 | [Security and privacy](prd/16-security-and-privacy.md) | Threats, DPDP, phone masking |
| 17 | [Notifications](prd/17-notifications.md) | Event matrix and copy |
| 18 | [Analytics](prd/18-analytics.md) | Event taxonomy |
| 19 | [Observability](prd/19-observability.md) | Logs, alerts, incidents |
| 20 | [Testing](prd/20-testing.md) | Pyramid and critical cases |
| 21 | [DevOps](prd/21-devops.md) | Environments, CI, secrets |
| 22 | [Coding standards](prd/22-coding-standards.md) | Calibration rules and boundaries |
| 23 | [Risk register](prd/23-risks.md) | Likelihood, impact, mitigation |
| 24 | [Out of scope](prd/24-out-of-scope.md) | Phase 2 backlog |
| 25 | [Glossary and appendices](prd/25-glossary-and-appendices.md) | Terms, sample payloads, rules |

## Requirement prefix

| Prefix | Area |
| --- | --- |
| `FR-AUTH` | Sign-in, session, roles |
| `FR-BOOK` | Booking, catalog, cancellation, SOS |
| `FR-TRK` | Live location, ETA, share link |
| `FR-COM` | Chat and masked calling |
| `FR-VEH` | Vehicles and health |
| `FR-PAY` | Estimates, payments, wallet, coupons |
| `FR-INV` | Invoices |
| `FR-MEC` | Mechanic app, verification, parts photos |
| `FR-REV` | Reviews |
| `FR-NOT` | Notifications |
| `FR-USR` | Profile, dashboard, history |
| `FR-ADM` | Admin, RBAC, disputes |
| `NFR-*` | Quality attributes |

MoSCoW priorities: **Must** (MVP), **Should** (MVP if the milestone stays small), **Could** (only if free), **Won't** (Phase 2, see chapter 24).

## Golden rule

Clients may read realtime data from Firebase under Security Rules. Anything that changes booking status, pricing, payments, wallet, coupons, rating aggregates, or verification is written only by FastAPI using the Firebase Admin SDK. The one deliberate exception is a client's own live-location node, specified in [chapter 10](prd/10-hybrid-backend.md).
