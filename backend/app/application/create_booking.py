import hashlib
import json
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

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
from app.domain.coupon import CouponContext
from app.domain.errors import (
    AccountSuspended,
    BookingInProgress,
    IdempotencyConflict,
    IdempotencyKeyRequired,
    InsufficientWallet,
    InvalidInput,
    NotFound,
    PermissionDenied,
)
from app.domain.geo import haversine_km
from app.domain.pricing import PricingService
from app.domain.user import Principal, Role, UserStatus
from app.ports.address_repository import AddressRepository
from app.ports.analytics_service import AnalyticsService
from app.ports.booking_repository import BookingRepository
from app.ports.catalog_repository import CatalogRepository
from app.ports.clock import Clock
from app.ports.coupon_service import CouponService
from app.ports.dispatch_service import DispatchService
from app.ports.idempotency_store import IdempotencyRecord, IdempotencyStore
from app.ports.user_repository import UserRepository
from app.ports.vehicle_repository import VehicleRepository
from app.ports.wallet_service import WalletService

IST = ZoneInfo("Asia/Kolkata")


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
    coupons: CouponService | None = None
    wallet: WalletService | None = None
    dispatch: DispatchService | None = None
    users: UserRepository | None = None
    analytics: AnalyticsService | None = None

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
        if self.users is not None:
            account = await self.users.get(principal.user_id)
            if account is not None and account.status is UserStatus.SUSPENDED:
                raise AccountSuspended("This account is suspended.")
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

        if self.wallet is not None and (await self.wallet.balance(principal.user_id)).paise < 0:
            raise InsufficientWallet("Clear your cancellation fee before booking again.")

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
        start = self._check_schedule(effective_mode, urgency, scheduled_start, now)

        base = self.pricing.quote(QuoteInput(service=service, vehicle_type=vehicle.vehicle_type))
        discount = 0
        code = coupon_code.strip()
        if code and self.coupons is not None:
            prior = await self.bookings.list_by_customer(principal.user_id)
            quoted = await self.coupons.validate(
                code,
                CouponContext(
                    user_id=principal.user_id,
                    labor_paise=base.labor_paise,
                    prior_booking_count=len(prior),
                ),
            )
            discount = quoted.discount_paise
        quote = self.pricing.quote(
            QuoteInput(
                service=service,
                vehicle_type=vehicle.vehicle_type,
                discount_paise=discount,
            )
        )
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
            coupon_code=code,
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
        if self.analytics is not None:
            await self.analytics.track(
                "booking_submitted",
                {
                    "mode": saved.mode.value,
                    "urgency": saved.urgency.value,
                    "serviceCode": saved.service_code,
                    "method": saved.payment_method.value,
                },
            )
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
        self,
        mode: BookingMode,
        urgency: Urgency,
        scheduled_start: datetime | None,
        now: datetime,
    ) -> datetime | None:
        if mode is BookingMode.INSTANT:
            if urgency is not Urgency.SOS:
                local = now.astimezone(IST)
                open_min = self.policy.instant_open_hour_ist * 60
                close_min = self.policy.instant_close_hour_ist * 60
                minutes = local.hour * 60 + local.minute
                if minutes < open_min or minutes >= close_min:
                    raise InvalidInput(
                        "Out of booking hours. Instant booking is 7:00–21:00 IST. "
                        "Schedule a slot or use SOS."
                    )
            return None
        if scheduled_start is None:
            raise InvalidInput("Pick a start time for a scheduled booking.")
        start = (
            scheduled_start.replace(tzinfo=IST)
            if scheduled_start.tzinfo is None
            else scheduled_start
        ).astimezone(UTC)
        earliest = now + timedelta(minutes=self.policy.scheduled_min_lead_minutes)
        latest = now + timedelta(days=self.policy.scheduled_max_days)
        if start < earliest or start > latest:
            raise InvalidInput("Choose a time between 90 minutes and 7 days from now.")
        local = start.astimezone(IST)
        if local.minute != 0 or local.second != 0 or local.microsecond != 0:
            raise InvalidInput("Scheduled times must be on the hour.")
        return start
