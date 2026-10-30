# 019 — Mechanic session ticker

Heartbeat and open-offer polling used to live on `MechanicHomeScreen`. Leaving
home after Accept cancelled the timer, so assigned jobs could look stale to
sweep after `assigned_stale_seconds`.

The ticker is a Riverpod notifier started from the mechanic app widget. It
heartbeats while `online` is true on any screen. Home still presents Go online
and consumes a pending offer id for navigation.

Rollback: move the 4s timer back onto home only.
