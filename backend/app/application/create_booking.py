import hashlib
import json
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingLine,
    BookingMode,
    BookingPolicy,
    LineKind,
    LineStatus,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import ACTIVE_STATUSES, BookingStatus
from app.domain.catalog import QuoteInput
from app.domain.errors import (
    BookingInProgress,
    IdempotencyConflict,
    IdempotencyKeyRequired,
    InvalidInput,
    NotFound,
    PermissionDenied,
)
from app.domain.geo import haversine_km
from app.domain.pricing import PricingService
from app.domain.user import Principal, Role
from app.ports.address_repository import AddressRepository
from app.ports.booking_repository import BookingRepository
from app.ports.catalog_repository import CatalogRepository
from app.ports.clock import Clock
from app.ports.dispatch_service import DispatchService
from app.ports.idempotency_store import IdempotencyRecord, IdempotencyStore
from app.ports.vehicle_repository import VehicleRepository


def parse_idempotency_key(raw: str | None) -> str:
    if raw is None or not raw.strip():
        raise IdempotencyKeyRequired("Idempotency-Key is required to create a booking.")
    try:
        return str(uuid.UUID(raw.strip()))
    except ValueError as exc:
        raise InvalidInput("Idempotency-Key must be a UUID.") from exc


def hash_create_body(fields: dict[str, object]) -> str:
    canonical = json.dumps(fields, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(canonical.encode()).hexdigest()


def display_number_for(booking_id: str) -> str:
    return f"MC{booking_id.replace('-', '')[:8].upper()}"


@dataclass(frozen=True)
class CreateBooking:
    """Create one on-site booking. Prices through PricingService. Instant
    confirmed jobs start sequential dispatch when a DispatchService is bound.
    """

    catalog: CatalogRepository
    vehicles: VehicleRepository
    bookings: BookingRepository
    addresses: AddressRepository
    idempotency: IdempotencyStore
    pricing: PricingService
    clock: Clock
    policy: BookingPolicy
    dispatch: DispatchService | None = None

    async def execute(
        self,
        principal: Principal,
        *,
        idempotency_key: str | None,
        vehicle_id: str,
        service_code: str,
        address_id: str,
        mode: BookingMode,
        urgency: Urgency,
        payment_method: PaymentMethod,
        coupon_code: str = "",
        scheduled_start: datetime | None = None,
    ) -> Booking:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        key = parse_idempotency_key(idempotency_key)
        body: dict[str, object] = {
            "vehicleId": vehicle_id,
            "serviceCode": service_code,
            "addressId": address_id,
            "mode": mode.value,
            "urgency": urgency.value,
            "paymentMethod": payment_method.value,
            "couponCode": coupon_code,
            "scheduledStart": scheduled_start.isoformat() if scheduled_start else None,
        }
        body_hash = hash_create_body(body)
        now = self.clock.now()
        existing = await self._replay(principal.user_id, key, body_hash, now)
        if existing is not None:
            return existing

        if coupon_code.strip():
            raise InvalidInput("Coupons arrive in M10.")

        effective_mode = BookingMode.INSTANT if urgency is Urgency.SOS else mode
        effective_code = "breakdown" if urgency is Urgency.SOS else service_code

        await self._reject_if_active(principal.user_id)

        vehicle = await self.vehicles.get(vehicle_id, principal.user_id)
        if vehicle is None:
            raise NotFound("We could not find that vehicle.")
        service = await self.catalog.get_service(effective_code)
        if service is None:
            raise NotFound("We could not find that service.")
        if not service.active:
            raise InvalidInput("This service is not available.")
        address = await self.addresses.get(principal.user_id, address_id)
        if address is None:
            raise NotFound("We could not find that address.")
        self._check_service_area(address)
        start = self._check_schedule(effective_mode, scheduled_start, now)

        quote = self.pricing.quote(QuoteInput(service=service, vehicle_type=vehicle.vehicle_type))
        booking_id = str(uuid.uuid4())
        status = BookingStatus.CONFIRMED if self.policy.auto_confirm else BookingStatus.REQUESTED
        labor_line = BookingLine(
            id=str(uuid.uuid4()),
            kind=LineKind.LABOR,
            name=service.name,
            amount_paise=quote.labor_paise,
            gst_paise=quote.cgst_paise + quote.sgst_paise,
            status=LineStatus.INCLUDED,
        )
        booking = Booking(
            id=booking_id,
            display_number=display_number_for(booking_id),
            customer_id=principal.user_id,
            vehicle_id=vehicle.id,
            service_code=service.code,
            service_name=service.name,
            mode=effective_mode,
            urgency=urgency,
            status=status,
            payment_method=payment_method,
            address=address,
            labor_paise=quote.labor_paise,
            parts_paise=quote.parts_paise,
            fee_paise=quote.fee_paise,
            discount_paise=quote.discount_paise,
            cgst_paise=quote.cgst_paise,
            sgst_paise=quote.sgst_paise,
            total_paise=quote.total_paise,
            cancel_fee_paise=0,
            cancel_reason=None,
            scheduled_start=start,
            mechanic_id=None,
            lines=(labor_line,),
            created_at=now,
            updated_at=now,
            version=1,
        )
        saved = await self.bookings.save(booking)
        await self.idempotency.put(
            principal.user_id,
            key,
            IdempotencyRecord(body_hash=body_hash, booking_id=saved.id, created_at=now),
        )
        if (
            self.dispatch is not None
            and saved.status is BookingStatus.CONFIRMED
            and saved.mode is BookingMode.INSTANT
        ):
            await self.dispatch.offer(saved.id)
            reloaded = await self.bookings.get(saved.id)
            if reloaded is not None:
                saved = reloaded
        return saved

    async def _replay(
        self, user_id: str, key: str, body_hash: str, now: datetime
    ) -> Booking | None:
        record = await self.idempotency.get(user_id, key)
        if record is None:
            return None
        ttl = timedelta(hours=self.policy.idempotency_ttl_hours)
        if now - record.created_at > ttl:
            return None
        if record.body_hash != body_hash:
            raise IdempotencyConflict("This key was already used with a different request.")
        booking = await self.bookings.get(record.booking_id)
        if booking is None:
            raise IdempotencyConflict("This key was already used with a different request.")
        return booking

    async def _reject_if_active(self, customer_id: str) -> None:
        current = await self.bookings.list_by_customer(customer_id)
        if any(b.status in ACTIVE_STATUSES for b in current):
            raise BookingInProgress("You already have a booking in progress.")

    def _check_service_area(self, address: AddressSnapshot) -> None:
        distance = haversine_km(
            address.lat,
            address.lng,
            self.policy.service_area_lat,
            self.policy.service_area_lng,
        )
        if distance > self.policy.service_area_radius_km:
            raise InvalidInput("That address is outside our service area.")

    def _check_schedule(
        self, mode: BookingMode, scheduled_start: datetime | None, now: datetime
    ) -> datetime | None:
        if mode is BookingMode.INSTANT:
            return None
        if scheduled_start is None:
            raise InvalidInput("Pick a start time for a scheduled booking.")
        start = scheduled_start if scheduled_start.tzinfo else scheduled_start.replace(tzinfo=UTC)
        earliest = now + timedelta(minutes=self.policy.scheduled_min_lead_minutes)
        latest = now + timedelta(days=self.policy.scheduled_max_days)
        if start < earliest or start > latest:
            raise InvalidInput("Choose a time between 90 minutes and 7 days from now.")
        if start.minute != 0 or start.second != 0 or start.microsecond != 0:
            raise InvalidInput("Scheduled times must be on the hour.")
        return start
