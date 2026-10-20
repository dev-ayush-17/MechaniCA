"""Sequential DispatchService. One open offer per booking (ADR-013)."""

from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass, replace
from datetime import datetime, timedelta

from app.application.location_gate import sync_location_gate
from app.domain.booking import Booking, BookingMode, Urgency
from app.domain.booking_state import BookingStatus, assert_transition
from app.domain.dispatch import (
    DispatchConfig,
    Offer,
    OfferStatus,
    RankedCandidate,
    acceptance_rate,
    offer_ttl_seconds,
    radii_km,
    score_candidate,
)
from app.domain.errors import InvalidTransition, NotFound, OfferGone, PermissionDenied
from app.domain.geo import haversine_km
from app.domain.mechanic import Mechanic
from app.domain.notification_templates import Channel
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.job_scheduler import JobScheduler, ScheduledJob
from app.ports.location_tracking import LocationTrackingService
from app.ports.mechanic_repository import MechanicRepository
from app.ports.notification_sender import NotificationSender, OutboundNotification
from app.ports.offer_repository import OfferRepository

_LOG = logging.getLogger("mechupp.dispatch")

_BUSY = frozenset(
    {
        BookingStatus.MECHANIC_ASSIGNED,
        BookingStatus.EN_ROUTE,
        BookingStatus.ARRIVED,
        BookingStatus.IN_SERVICE,
    }
)


@dataclass(frozen=True)
class SequentialDispatch:
    bookings: BookingRepository
    offers: OfferRepository
    mechanics: MechanicRepository
    notifications: NotificationSender
    clock: Clock
    config: DispatchConfig = DispatchConfig()
    scheduler: JobScheduler | None = None
    locations: LocationTrackingService | None = None

    async def offer(self, booking_id: str) -> Offer | None:
        booking = await self._load_booking(booking_id)
        if booking.status is BookingStatus.FAILED:
            return None
        if booking.status is not BookingStatus.CONFIRMED:
            raise InvalidTransition("Dispatch only runs on a confirmed booking.")
        if booking.mode is BookingMode.SCHEDULED and not self._scheduled_due(booking):
            return None
        existing = await self.offers.list_by_booking(booking.id)
        open_offers = [item for item in existing if item.status is OfferStatus.OPEN]
        if open_offers:
            return open_offers[0]
        attempt = len(existing) + 1
        if attempt > self.config.max_attempts:
            await self._fail(booking)
            return None
        candidate = await self._pick(booking, existing)
        if candidate is None:
            await self._fail(booking)
            return None
        now = self.clock.now()
        ttl = timedelta(seconds=offer_ttl_seconds(booking.urgency, self.config))
        created = Offer(
            id=str(uuid.uuid4()),
            booking_id=booking.id,
            mechanic_id=candidate.mechanic_id,
            status=OfferStatus.OPEN,
            expires_at=now + ttl,
            attempt=attempt,
            score=candidate.score,
            distance_km=candidate.distance_km,
            created_at=now,
        )
        saved = await self.offers.save(created)
        updated = booking.with_status(BookingStatus.CONFIRMED, now=now, dispatch_attempt=attempt)
        await self.bookings.save(updated)
        await self._schedule_timeout(saved.id, saved.expires_at)
        await self._notify(
            OutboundNotification(
                user_id=candidate.mechanic_id,
                channel=Channel.PUSH,
                template_id="offerCreated",
                title="New job nearby",
                body=booking.service_name,
                data={
                    "bookingId": booking.id,
                    "serviceName": booking.service_name,
                    "distanceKm": f"{candidate.distance_km:.1f}",
                    "totalPaise": str(booking.total_paise),
                    "secondsLeft": str(int(ttl.total_seconds())),
                },
                deep_link=f"/mechanic/offers/{saved.id}",
            )
        )
        return saved

    async def accept(self, offer_id: str, mechanic_id: str) -> Booking:
        offer = await self._load_offer(offer_id)
        if offer.mechanic_id != mechanic_id:
            raise OfferGone("This job was offered to someone else.")
        booking = await self._load_booking(offer.booking_id)
        if offer.status is OfferStatus.ACCEPTED:
            return booking
        if offer.status is not OfferStatus.OPEN:
            raise OfferGone("This job is no longer available.")
        now = self.clock.now()
        await self.offers.save(replace(offer, status=OfferStatus.ACCEPTED))
        assert_transition(booking.status, BookingStatus.MECHANIC_ASSIGNED, "system")
        assigned = booking.with_status(
            BookingStatus.MECHANIC_ASSIGNED, now=now, mechanic_id=mechanic_id
        )
        saved = await self.bookings.save(assigned)
        await self._sync_gate(saved)
        await self._notify(
            OutboundNotification(
                user_id=booking.customer_id,
                channel=Channel.PUSH,
                template_id="mechanicAssigned",
                title="Mechanic assigned",
                body="Your mechanic is on the way.",
                data={"bookingId": booking.id, "mechanicId": mechanic_id},
                deep_link=f"/tracking?id={booking.id}",
            )
        )
        return saved

    async def reject(self, offer_id: str, mechanic_id: str) -> None:
        offer = await self._load_offer(offer_id)
        if offer.mechanic_id != mechanic_id:
            raise PermissionDenied("This offer is not yours.")
        if offer.status is not OfferStatus.OPEN:
            return
        await self.offers.save(replace(offer, status=OfferStatus.REJECTED))
        await self._advance(offer.booking_id)

    async def expire(self, offer_id: str) -> None:
        offer = await self._load_offer(offer_id)
        if offer.status is not OfferStatus.OPEN:
            return
        await self.offers.save(replace(offer, status=OfferStatus.EXPIRED))
        await self._notify(
            OutboundNotification(
                user_id=offer.mechanic_id,
                channel=Channel.IN_APP,
                template_id="offerExpired",
                title="Offer expired",
                body="This job was offered to someone else.",
                data={"offerId": offer.id},
                deep_link="/mechanic/home",
            )
        )
        await self._advance(offer.booking_id)

    async def _advance(self, booking_id: str) -> None:
        booking = await self._load_booking(booking_id)
        existing = await self.offers.list_by_booking(booking.id)
        if len(existing) >= self.config.max_attempts:
            await self._fail(booking)
            return
        if booking.status is BookingStatus.MECHANIC_ASSIGNED:
            booking = booking.with_status(BookingStatus.CONFIRMED, now=self.clock.now())
            await self.bookings.save(booking)
            await self._sync_gate(booking)
        elif booking.status is not BookingStatus.CONFIRMED:
            return
        await self.offer(booking.id)

    async def _fail(self, booking: Booking) -> None:
        if booking.status is BookingStatus.FAILED:
            return
        now = self.clock.now()
        failed = booking.with_status(BookingStatus.FAILED, now=now, failure_reason="no_mechanic")
        await self.bookings.save(failed)
        await self._sync_gate(failed)
        await self._notify(
            OutboundNotification(
                user_id=booking.customer_id,
                channel=Channel.PUSH,
                template_id="bookingFailed",
                title="No mechanic available",
                body="We could not find a mechanic. Try again.",
                data={"bookingId": booking.id, "urgency": booking.urgency.value},
                deep_link=f"/booking/details?id={booking.id}",
            )
        )

    async def _pick(self, booking: Booking, existing: list[Offer]) -> RankedCandidate | None:
        excluded = {item.mechanic_id for item in existing}
        now = self.clock.now()
        for radius in radii_km(booking.urgency, self.config):
            nearby = await self.mechanics.find_online_near(
                booking.address.lat, booking.address.lng, radius, 50
            )
            ranked: list[RankedCandidate] = []
            for mechanic in nearby:
                if mechanic.id in excluded or await self._is_busy(mechanic.id):
                    continue
                if not self._heartbeat_fresh(mechanic, now):
                    continue
                if not self._covers_job(mechanic, booking):
                    continue
                distance = haversine_km(
                    booking.address.lat,
                    booking.address.lng,
                    mechanic.service_area.lat if mechanic.service_area else 0.0,
                    mechanic.service_area.lng if mechanic.service_area else 0.0,
                )
                history = await self.offers.list_by_mechanic(mechanic.id)
                ranked.append(
                    RankedCandidate(
                        mechanic_id=mechanic.id,
                        score=self._score(mechanic, history, distance, booking.urgency, now),
                        distance_km=distance,
                    )
                )
            if ranked:
                ranked.sort(key=lambda item: item.score, reverse=True)
                return ranked[0]
        return None

    def _score(
        self,
        mechanic: Mechanic,
        history: list[Offer],
        distance: float,
        urgency: Urgency,
        now: datetime,
    ) -> float:
        window = now - timedelta(days=self.config.acceptance_window_days)
        recent_since = now - timedelta(minutes=self.config.recent_offers_minutes)
        accepts = sum(
            1
            for item in history
            if item.status is OfferStatus.ACCEPTED and item.created_at >= window
        )
        rejects = sum(
            1
            for item in history
            if item.status is OfferStatus.REJECTED and item.created_at >= window
        )
        timeouts = sum(
            1
            for item in history
            if item.status is OfferStatus.EXPIRED and item.created_at >= window
        )
        recent = sum(1 for item in history if item.created_at >= recent_since)
        return score_candidate(
            rating_avg=mechanic.rating_avg,
            rating_count=mechanic.rating_count,
            acceptance=acceptance_rate(accepts, rejects, timeouts, self.config),
            distance_km=distance,
            recent_offers=recent,
            urgency=urgency,
            config=self.config,
        )

    async def _is_busy(self, mechanic_id: str) -> bool:
        jobs = await self.bookings.list_by_mechanic(mechanic_id)
        return any(job.status in _BUSY for job in jobs)

    def _heartbeat_fresh(self, mechanic: Mechanic, now: datetime) -> bool:
        beat = mechanic.last_heartbeat_at
        if beat is None:
            return False
        return (now - beat).total_seconds() <= self.config.heartbeat_fresh_seconds

    def _covers_job(self, mechanic: Mechanic, booking: Booking) -> bool:
        area = mechanic.service_area
        if area is None:
            return False
        distance = haversine_km(booking.address.lat, booking.address.lng, area.lat, area.lng)
        return distance <= area.radius_km

    def _scheduled_due(self, booking: Booking) -> bool:
        start = booking.scheduled_start
        if start is None:
            return False
        return self.clock.now() >= start - timedelta(minutes=60)

    async def _load_booking(self, booking_id: str) -> Booking:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        return booking

    async def _load_offer(self, offer_id: str) -> Offer:
        offer = await self.offers.get(offer_id)
        if offer is None:
            raise NotFound("We could not find that offer.")
        return offer

    async def _schedule_timeout(self, offer_id: str, expires_at: datetime) -> None:
        if self.scheduler is None:
            return
        try:
            await self.scheduler.schedule(
                ScheduledJob(
                    id=f"offer-timeout-{offer_id}",
                    run_at=expires_at,
                    target_path="/v1/internal/jobs/dispatch-timeout",
                    body={"offerId": offer_id},
                )
            )
        except Exception as exc:
            _LOG.warning(
                "schedule_failed",
                extra={"fields": {"offerId": offer_id, "error": type(exc).__name__}},
            )

    async def _sync_gate(self, booking: Booking) -> None:
        if self.locations is None:
            return
        await sync_location_gate(self.locations, booking)

    async def _notify(self, message: OutboundNotification) -> None:
        try:
            await self.notifications.send(message)
        except Exception as exc:
            _LOG.warning(
                "notification_send_failed",
                extra={"fields": {"template": message.template_id, "error": type(exc).__name__}},
            )
