"""Composition root: the only place that decides which adapter implements a port."""

from functools import lru_cache
from typing import Annotated

from fastapi import Depends, Header

from app.adapters.fake.address_repository import FakeAddressRepository
from app.adapters.fake.audit_log import FakeAuditLog
from app.adapters.fake.auth import FakeAuth
from app.adapters.fake.booking_repository import FakeBookingRepository
from app.adapters.fake.catalog_repository import FakeCatalogRepository
from app.adapters.fake.chat_service import FakeChatService
from app.adapters.fake.coupon_service import FakeCouponService
from app.adapters.fake.device_token_repository import FakeDeviceTokenRepository
from app.adapters.fake.file_storage import FakeFileStorage
from app.adapters.fake.idempotency_store import FakeIdempotencyStore
from app.adapters.fake.invoice_repository import FakeInvoiceRepository
from app.adapters.fake.job_scheduler import FakeJobScheduler
from app.adapters.fake.mechanic_repository import FakeMechanicRepository
from app.adapters.fake.notification_repository import FakeNotificationRepository
from app.adapters.fake.notification_sender import RecordingNotificationSender
from app.adapters.fake.offer_repository import FakeOfferRepository
from app.adapters.fake.parts_proof_repository import FakePartsProofRepository
from app.adapters.fake.payment_gateway import FakePaymentGateway
from app.adapters.fake.payment_repository import FakePaymentRepository
from app.adapters.fake.readiness import FakeReadiness
from app.adapters.fake.review_repository import FakeReviewRepository
from app.adapters.fake.telephony import FakeTelephony
from app.adapters.fake.user_repository import FakeUserRepository
from app.adapters.fake.wallet_service import FakeWalletService
from app.adapters.pdf import render_invoice_pdf
from app.adapters.system_clock import SystemClock
from app.application.apply_payment import ApplyGatewayEvent
from app.application.bootstrap_user import BootstrapUser
from app.application.cancel_booking import CancelBooking
from app.application.cash_confirm import ConfirmCash, MarkCashCollected, StaffConfirmCash
from app.application.create_booking import CreateBooking
from app.application.create_mechanic_draft import CreateMechanicDraft
from app.application.create_payment import CreatePayment
from app.application.create_quote import CreateQuote
from app.application.dispatch import SequentialDispatch
from app.application.expire_extra_line import ExpireExtraLine
from app.application.expire_offer import ExpireOffer
from app.application.extra_line import AddExtraLine, DecideExtraLine
from app.application.get_booking import GetBooking
from app.application.invoices import DefaultInvoiceService, GetInvoice
from app.application.list_earnings import ListEarnings
from app.application.manage_notifications import ManageNotifications
from app.application.manage_vehicles import ManageVehicles
from app.application.mask_call import MaskCall
from app.application.mechanic_heartbeat import MechanicHeartbeat
from app.application.notify import Notify
from app.application.parts_proofs import CreatePartsProof, HidePartsProof, ListPartsProofs
from app.application.reconcile_payments import ReconcilePendingPayments
from app.application.refund_payment import RefundPayment
from app.application.register_device import RegisterDevice
from app.application.reviews import EditReview, HideReview, ListReviews, SubmitReview
from app.application.send_message import SendMessage
from app.application.set_mechanic_availability import SetMechanicAvailability
from app.application.sign_chat_media import SignChatMedia
from app.application.sign_upload import SignUpload
from app.application.submit_mechanic_application import SubmitMechanicApplication
from app.application.sweep_jobs import SweepExpiredOffers
from app.application.transition_booking import TransitionBooking
from app.application.verify_mechanic import VerifyMechanic
from app.application.wallet_topup import CreateWalletTopup
from app.core.config import Settings, get_settings
from app.domain.booking import BookingPolicy
from app.domain.catalog import PricingConfig
from app.domain.errors import PermissionDenied, Unauthenticated
from app.domain.pricing import PricingService
from app.domain.user import Principal, Role
from app.ports.address_repository import AddressRepository
from app.ports.audit_log import AuditLog
from app.ports.auth_verifier import AuthVerifier
from app.ports.booking_repository import BookingRepository
from app.ports.catalog_repository import CatalogRepository
from app.ports.chat_service import ChatService
from app.ports.clock import Clock
from app.ports.coupon_service import CouponService
from app.ports.device_token_repository import DeviceTokenRepository
from app.ports.file_storage import FileStorage
from app.ports.idempotency_store import IdempotencyStore
from app.ports.invoice_repository import InvoiceRepository
from app.ports.job_scheduler import JobScheduler
from app.ports.mechanic_repository import MechanicRepository
from app.ports.notification_repository import NotificationRepository
from app.ports.notification_sender import NotificationSender
from app.ports.offer_repository import OfferRepository
from app.ports.parts_proof_repository import PartsProofRepository
from app.ports.payment_gateway import PaymentGateway
from app.ports.payment_repository import PaymentRepository
from app.ports.readiness import ReadinessCheck
from app.ports.review_repository import ReviewRepository
from app.ports.role_claims import RoleClaims
from app.ports.telephony import TelephonyPort
from app.ports.user_repository import UserRepository
from app.ports.vehicle_repository import VehicleRepository
from app.ports.wallet_service import WalletService


def settings_dep() -> Settings:
    return get_settings()


@lru_cache
def _clock() -> Clock:
    return SystemClock()


def clock_dep() -> Clock:
    return _clock()


@lru_cache
def _readiness() -> ReadinessCheck:
    # Later milestones add Firestore and task-queue adapters, selected by Settings.
    return FakeReadiness()


def readiness_dep() -> ReadinessCheck:
    return _readiness()


class _AuthBinding:
    """One vendor object serves both the verifier and the claims port."""

    def __init__(self, verifier: AuthVerifier, claims: RoleClaims) -> None:
        self.verifier = verifier
        self.claims = claims


@lru_cache
def _auth() -> _AuthBinding:
    settings = get_settings()
    if settings.provider_auth == "firebase":
        # Imported here so the Firebase SDK loads only when this adapter is selected.
        from app.adapters.firebase.auth_verifier import FirebaseAuth

        assert settings.firebase_project_id is not None  # noqa: S101 - Settings guarantees it
        firebase = FirebaseAuth(settings.firebase_project_id)
        return _AuthBinding(firebase, firebase)
    fake = FakeAuth(settings.app_env)
    return _AuthBinding(fake, fake)


def auth_verifier_dep() -> AuthVerifier:
    return _auth().verifier


def role_claims_dep() -> RoleClaims:
    return _auth().claims


@lru_cache
def _users() -> UserRepository:
    # A Firestore adapter replaces this in a later milestone. Until then users live in memory.
    return FakeUserRepository()


def user_repository_dep() -> UserRepository:
    return _users()


async def principal_dep(
    verifier: Annotated[AuthVerifier, Depends(auth_verifier_dep)],
    authorization: Annotated[str | None, Header()] = None,
) -> Principal:
    """Resolve the bearer token to a Principal. 401 when it is missing or invalid."""
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise Unauthenticated("Sign in again.")
    return await verifier.verify(token.strip())


@lru_cache
def _vehicles() -> VehicleRepository:
    settings = get_settings()
    if settings.provider_vehicles == "firestore":
        from app.adapters.firebase.vehicle_repository import FirestoreVehicleRepository

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreVehicleRepository(settings.firebase_project_id)
    from app.adapters.fake.vehicle_repository import FakeVehicleRepository

    return FakeVehicleRepository()


def vehicle_repository_dep() -> VehicleRepository:
    return _vehicles()


@lru_cache
def _catalog() -> CatalogRepository:
    settings = get_settings()
    if settings.provider_catalog == "firestore":
        from app.adapters.firebase.catalog_repository import FirestoreCatalogRepository

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreCatalogRepository(settings.firebase_project_id)
    return FakeCatalogRepository()


def catalog_repository_dep() -> CatalogRepository:
    return _catalog()


def pricing_service_dep(
    settings: Annotated[Settings, Depends(settings_dep)],
) -> PricingService:
    return PricingService(
        PricingConfig(
            convenience_fee_paise=settings.convenience_fee_paise,
            four_wheeler_labor_bps=settings.four_wheeler_labor_bps,
            gst_bps=settings.gst_bps,
        )
    )


@lru_cache
def _payments() -> PaymentRepository:
    return FakePaymentRepository()


def payment_repository_dep() -> PaymentRepository:
    return _payments()


@lru_cache
def _wallet() -> WalletService:
    return FakeWalletService()


def wallet_service_dep() -> WalletService:
    return _wallet()


@lru_cache
def _coupons() -> CouponService:
    return FakeCouponService()


def coupon_service_dep() -> CouponService:
    return _coupons()


@lru_cache
def _payment_gateway() -> PaymentGateway:
    settings = get_settings()
    if settings.provider_payments == "cashfree":
        from app.adapters.cashfree.payment_gateway import CashfreePaymentGateway

        assert settings.cashfree_app_id is not None  # noqa: S101
        assert settings.cashfree_secret is not None  # noqa: S101
        return CashfreePaymentGateway(
            app_id=settings.cashfree_app_id,
            secret=settings.cashfree_secret,
            api_url=settings.cashfree_api_url,
            app_env=settings.app_env,
        )
    return FakePaymentGateway(secret=settings.payments_webhook_secret)


def payment_gateway_dep() -> PaymentGateway:
    return _payment_gateway()


def manage_vehicles_dep(
    vehicles: Annotated[VehicleRepository, Depends(vehicle_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> ManageVehicles:
    return ManageVehicles(vehicles=vehicles, clock=clock)


def bootstrap_user_dep(
    users: Annotated[UserRepository, Depends(user_repository_dep)],
    claims: Annotated[RoleClaims, Depends(role_claims_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> BootstrapUser:
    return BootstrapUser(
        users=users, claims=claims, clock=clock, auth_provider=settings.provider_auth
    )


@lru_cache
def _mechanics() -> FakeMechanicRepository:
    return FakeMechanicRepository()


def mechanic_repository_dep() -> MechanicRepository:
    return _mechanics()


@lru_cache
def _storage() -> FileStorage:
    return FakeFileStorage()


def file_storage_dep() -> FileStorage:
    return _storage()


@lru_cache
def _invoices() -> FakeInvoiceRepository:
    return FakeInvoiceRepository()


def invoice_repository_dep() -> InvoiceRepository:
    return _invoices()


@lru_cache
def _audit() -> AuditLog:
    return FakeAuditLog()


def audit_log_dep() -> AuditLog:
    return _audit()


async def require_mechanic_dep(
    principal: Annotated[Principal, Depends(principal_dep)],
) -> Principal:
    if principal.role != Role.MECHANIC:
        raise PermissionDenied("Mechanic account required.")
    return principal


async def admin_principal_dep(
    principal: Annotated[Principal, Depends(principal_dep)],
) -> Principal:
    if principal.role not in (Role.ADMIN, Role.SUPER_ADMIN):
        raise PermissionDenied("Admin access required.")
    return principal


def create_mechanic_draft_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> CreateMechanicDraft:
    return CreateMechanicDraft(mechanics=mechanics, clock=clock)


def submit_mechanic_application_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> SubmitMechanicApplication:
    return SubmitMechanicApplication(mechanics=mechanics, clock=clock)


def set_mechanic_availability_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
) -> SetMechanicAvailability:
    return SetMechanicAvailability(mechanics=mechanics)


def mechanic_heartbeat_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> MechanicHeartbeat:
    return MechanicHeartbeat(mechanics=mechanics, clock=clock)


def sign_upload_dep(
    storage: Annotated[FileStorage, Depends(file_storage_dep)],
) -> SignUpload:
    return SignUpload(storage=storage)


def verify_mechanic_dep(
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    claims: Annotated[RoleClaims, Depends(role_claims_dep)],
    audit: Annotated[AuditLog, Depends(audit_log_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> VerifyMechanic:
    return VerifyMechanic(mechanics=mechanics, claims=claims, audit=audit, clock=clock)


def booking_policy_dep(settings: Annotated[Settings, Depends(settings_dep)]) -> BookingPolicy:
    return BookingPolicy(
        auto_confirm=settings.booking_auto_confirm,
        cancel_fee_enroute_paise=settings.cancel_fee_enroute_paise,
        service_area_lat=settings.service_area_lat,
        service_area_lng=settings.service_area_lng,
        service_area_radius_km=settings.service_area_radius_km,
    )


@lru_cache
def _bookings() -> BookingRepository:
    settings = get_settings()
    if settings.provider_bookings == "firestore":
        from app.adapters.firebase.booking_repository import FirestoreBookingRepository

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreBookingRepository(settings.firebase_project_id)
    return FakeBookingRepository()


def booking_repository_dep() -> BookingRepository:
    return _bookings()


def invoice_service_dep(
    invoices: Annotated[InvoiceRepository, Depends(invoice_repository_dep)],
    storage: Annotated[FileStorage, Depends(file_storage_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    users: Annotated[UserRepository, Depends(user_repository_dep)],
    vehicles: Annotated[VehicleRepository, Depends(vehicle_repository_dep)],
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> DefaultInvoiceService:
    return DefaultInvoiceService(
        invoices=invoices,
        storage=storage,
        bookings=bookings,
        payments=payments,
        users=users,
        vehicles=vehicles,
        mechanics=mechanics,
        clock=clock,
        gstin=settings.gstin,
        render_pdf=render_invoice_pdf,
    )


def get_invoice_dep(
    invoices: Annotated[DefaultInvoiceService, Depends(invoice_service_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    storage: Annotated[FileStorage, Depends(file_storage_dep)],
) -> GetInvoice:
    return GetInvoice(invoices=invoices, bookings=bookings, storage=storage)


def create_quote_dep(
    catalog: Annotated[CatalogRepository, Depends(catalog_repository_dep)],
    vehicles: Annotated[VehicleRepository, Depends(vehicle_repository_dep)],
    pricing: Annotated[PricingService, Depends(pricing_service_dep)],
    coupons: Annotated[CouponService, Depends(coupon_service_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
) -> CreateQuote:
    return CreateQuote(
        catalog=catalog,
        vehicles=vehicles,
        pricing=pricing,
        coupons=coupons,
        bookings=bookings,
    )


@lru_cache
def _offers() -> FakeOfferRepository:
    return FakeOfferRepository()


def offer_repository_dep() -> OfferRepository:
    return _offers()


@lru_cache
def _notifications() -> NotificationRepository:
    settings = get_settings()
    if settings.provider_notifications == "firestore":
        from app.adapters.firebase.notification_repository import FirestoreNotificationRepository

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreNotificationRepository(settings.firebase_project_id)
    return FakeNotificationRepository()


def notification_repository_dep() -> NotificationRepository:
    return _notifications()


@lru_cache
def _devices() -> DeviceTokenRepository:
    settings = get_settings()
    if settings.provider_notifications == "firestore":
        from app.adapters.firebase.device_token_repository import FirestoreDeviceTokenRepository

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreDeviceTokenRepository(settings.firebase_project_id)
    return FakeDeviceTokenRepository()


def device_token_repository_dep() -> DeviceTokenRepository:
    return _devices()


@lru_cache
def _notification_sender() -> NotificationSender:
    settings = get_settings()
    if settings.provider_notify == "fcm":
        from app.adapters.fcm import FcmNotificationSender

        assert settings.firebase_project_id is not None  # noqa: S101
        return FcmNotificationSender(
            settings.firebase_project_id,
            notifications=_notifications(),
            devices=_devices(),
            clock=_clock(),
        )
    return RecordingNotificationSender(notifications=_notifications(), clock=_clock())


def notification_sender_dep() -> NotificationSender:
    return _notification_sender()


@lru_cache
def _scheduler() -> JobScheduler:
    settings = get_settings()
    if settings.provider_scheduler == "cloud_tasks":
        from app.adapters.gcp.cloud_tasks_scheduler import CloudTasksJobScheduler

        assert settings.firebase_project_id is not None  # noqa: S101
        assert settings.cloud_tasks_service_account is not None  # noqa: S101
        return CloudTasksJobScheduler(
            project_id=settings.firebase_project_id,
            location=settings.cloud_tasks_location,
            queue=settings.cloud_tasks_queue,
            handler_base_url=settings.cloud_tasks_handler_base_url,
            service_account_email=settings.cloud_tasks_service_account,
        )
    return FakeJobScheduler()


def job_scheduler_dep() -> JobScheduler:
    return _scheduler()


async def require_internal_job_dep(
    x_internal_job_token: Annotated[str | None, Header()] = None,
) -> None:
    settings = get_settings()
    if not x_internal_job_token or x_internal_job_token != settings.internal_job_token:
        raise Unauthenticated("Internal job token required.")


def dispatch_service_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    offers: Annotated[OfferRepository, Depends(offer_repository_dep)],
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    notifications: Annotated[NotificationSender, Depends(notification_sender_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    scheduler: Annotated[JobScheduler, Depends(job_scheduler_dep)],
) -> SequentialDispatch:
    return SequentialDispatch(
        bookings=bookings,
        offers=offers,
        mechanics=mechanics,
        notifications=notifications,
        clock=clock,
        scheduler=scheduler,
    )


def expire_offer_dep(
    dispatch: Annotated[SequentialDispatch, Depends(dispatch_service_dep)],
) -> ExpireOffer:
    return ExpireOffer(dispatch=dispatch)


def expire_extra_line_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> ExpireExtraLine:
    return ExpireExtraLine(bookings=bookings, clock=clock)


def sweep_expired_offers_dep(
    offers: Annotated[OfferRepository, Depends(offer_repository_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    dispatch: Annotated[SequentialDispatch, Depends(dispatch_service_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    extra_lines: Annotated[ExpireExtraLine, Depends(expire_extra_line_dep)],
) -> SweepExpiredOffers:
    return SweepExpiredOffers(
        offers=offers,
        bookings=bookings,
        mechanics=mechanics,
        dispatch=dispatch,
        clock=clock,
        extra_lines=extra_lines,
    )


@lru_cache
def _idempotency() -> IdempotencyStore:
    settings = get_settings()
    if settings.provider_bookings == "firestore":
        from app.adapters.firebase.idempotency_store import FirestoreIdempotencyStore

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreIdempotencyStore(settings.firebase_project_id)
    return FakeIdempotencyStore()


def idempotency_store_dep() -> IdempotencyStore:
    return _idempotency()


@lru_cache
def _addresses() -> AddressRepository:
    return FakeAddressRepository()


def address_repository_dep() -> AddressRepository:
    return _addresses()


def create_booking_dep(
    catalog: Annotated[CatalogRepository, Depends(catalog_repository_dep)],
    vehicles: Annotated[VehicleRepository, Depends(vehicle_repository_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    addresses: Annotated[AddressRepository, Depends(address_repository_dep)],
    idempotency: Annotated[IdempotencyStore, Depends(idempotency_store_dep)],
    pricing: Annotated[PricingService, Depends(pricing_service_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    policy: Annotated[BookingPolicy, Depends(booking_policy_dep)],
    coupons: Annotated[CouponService, Depends(coupon_service_dep)],
    wallet: Annotated[WalletService, Depends(wallet_service_dep)],
    dispatch: Annotated[SequentialDispatch, Depends(dispatch_service_dep)],
) -> CreateBooking:
    return CreateBooking(
        catalog=catalog,
        vehicles=vehicles,
        bookings=bookings,
        addresses=addresses,
        idempotency=idempotency,
        pricing=pricing,
        clock=clock,
        policy=policy,
        coupons=coupons,
        wallet=wallet,
        dispatch=dispatch,
    )


@lru_cache
def _proofs() -> PartsProofRepository:
    return FakePartsProofRepository()


def parts_proof_repository_dep() -> PartsProofRepository:
    return _proofs()


def create_parts_proof_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    proofs: Annotated[PartsProofRepository, Depends(parts_proof_repository_dep)],
    storage: Annotated[FileStorage, Depends(file_storage_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> CreatePartsProof:
    return CreatePartsProof(bookings=bookings, proofs=proofs, storage=storage, clock=clock)


def list_parts_proofs_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    proofs: Annotated[PartsProofRepository, Depends(parts_proof_repository_dep)],
) -> ListPartsProofs:
    return ListPartsProofs(bookings=bookings, proofs=proofs)


def hide_parts_proof_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    proofs: Annotated[PartsProofRepository, Depends(parts_proof_repository_dep)],
) -> HidePartsProof:
    return HidePartsProof(bookings=bookings, proofs=proofs)


def get_booking_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
) -> GetBooking:
    return GetBooking(bookings=bookings)


def add_extra_line_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
    scheduler: Annotated[JobScheduler, Depends(job_scheduler_dep)],
) -> AddExtraLine:
    return AddExtraLine(
        bookings=bookings, clock=clock, gst_bps=settings.gst_bps, scheduler=scheduler
    )


def decide_extra_line_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> DecideExtraLine:
    return DecideExtraLine(bookings=bookings, clock=clock)


def create_payment_dep(
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    gateway: Annotated[PaymentGateway, Depends(payment_gateway_dep)],
    wallet: Annotated[WalletService, Depends(wallet_service_dep)],
    coupons: Annotated[CouponService, Depends(coupon_service_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
    scheduler: Annotated[JobScheduler, Depends(job_scheduler_dep)],
) -> CreatePayment:
    return CreatePayment(
        payments=payments,
        bookings=bookings,
        gateway=gateway,
        wallet=wallet,
        coupons=coupons,
        clock=clock,
        gst_bps=settings.gst_bps,
        scheduler=scheduler,
    )


def apply_gateway_event_dep(
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    wallet: Annotated[WalletService, Depends(wallet_service_dep)],
    audit: Annotated[AuditLog, Depends(audit_log_dep)],
    notifier: Annotated[NotificationSender, Depends(notification_sender_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    scheduler: Annotated[JobScheduler, Depends(job_scheduler_dep)],
) -> ApplyGatewayEvent:
    return ApplyGatewayEvent(
        payments=payments,
        bookings=bookings,
        wallet=wallet,
        audit=audit,
        notifier=notifier,
        clock=clock,
        scheduler=scheduler,
    )


def create_wallet_topup_dep(
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    gateway: Annotated[PaymentGateway, Depends(payment_gateway_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> CreateWalletTopup:
    return CreateWalletTopup(payments=payments, gateway=gateway, clock=clock)


def refund_payment_dep(
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    gateway: Annotated[PaymentGateway, Depends(payment_gateway_dep)],
    wallet: Annotated[WalletService, Depends(wallet_service_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> RefundPayment:
    return RefundPayment(payments=payments, gateway=gateway, wallet=wallet, clock=clock)


def list_earnings_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> ListEarnings:
    return ListEarnings(
        bookings=bookings, payments=payments, share_bps=settings.mechanic_labor_share_bps
    )


def mark_cash_collected_dep(
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    notifier: Annotated[NotificationSender, Depends(notification_sender_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> MarkCashCollected:
    return MarkCashCollected(payments=payments, bookings=bookings, notifier=notifier, clock=clock)


def confirm_cash_dep(
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    scheduler: Annotated[JobScheduler, Depends(job_scheduler_dep)],
) -> ConfirmCash:
    return ConfirmCash(payments=payments, bookings=bookings, clock=clock, scheduler=scheduler)


def reconcile_pending_dep(
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    gateway: Annotated[PaymentGateway, Depends(payment_gateway_dep)],
    apply: Annotated[ApplyGatewayEvent, Depends(apply_gateway_event_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> ReconcilePendingPayments:
    return ReconcilePendingPayments(payments=payments, gateway=gateway, apply=apply, clock=clock)


def staff_confirm_cash_dep(
    payments: Annotated[PaymentRepository, Depends(payment_repository_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    scheduler: Annotated[JobScheduler, Depends(job_scheduler_dep)],
) -> StaffConfirmCash:
    return StaffConfirmCash(
        payments=payments, bookings=bookings, clock=clock, scheduler=scheduler
    )


@lru_cache
def _reviews() -> ReviewRepository:
    return FakeReviewRepository()


def review_repository_dep() -> ReviewRepository:
    return _reviews()


def _blocked_words(settings: Settings) -> tuple[str, ...]:
    return tuple(word.strip() for word in settings.review_blocked_words.split(",") if word.strip())


def submit_review_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    reviews: Annotated[ReviewRepository, Depends(review_repository_dep)],
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> SubmitReview:
    return SubmitReview(
        bookings=bookings,
        reviews=reviews,
        mechanics=mechanics,
        clock=clock,
        blocked_words=_blocked_words(settings),
    )


def edit_review_dep(
    reviews: Annotated[ReviewRepository, Depends(review_repository_dep)],
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> EditReview:
    return EditReview(
        reviews=reviews,
        mechanics=mechanics,
        clock=clock,
        blocked_words=_blocked_words(settings),
    )


def list_reviews_dep(
    reviews: Annotated[ReviewRepository, Depends(review_repository_dep)],
) -> ListReviews:
    return ListReviews(reviews=reviews)


def hide_review_dep(
    reviews: Annotated[ReviewRepository, Depends(review_repository_dep)],
    mechanics: Annotated[MechanicRepository, Depends(mechanic_repository_dep)],
) -> HideReview:
    return HideReview(reviews=reviews, mechanics=mechanics)


@lru_cache
def _chat() -> ChatService:
    settings = get_settings()
    if settings.provider_chat == "firestore":
        from app.adapters.firebase.chat_service import FirestoreChatService

        assert settings.firebase_project_id is not None  # noqa: S101
        return FirestoreChatService(settings.firebase_project_id)
    return FakeChatService()


def chat_service_dep() -> ChatService:
    return _chat()


def send_message_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    chat: Annotated[ChatService, Depends(chat_service_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> SendMessage:
    return SendMessage(bookings=bookings, chat=chat, clock=clock)


def sign_chat_media_dep(
    storage: Annotated[FileStorage, Depends(file_storage_dep)],
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
) -> SignChatMedia:
    return SignChatMedia(storage=storage, bookings=bookings)


def telephony_port_dep(
    clock: Annotated[Clock, Depends(clock_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> TelephonyPort:
    if settings.provider_telephony == "unavailable":
        from app.adapters.telephony.unavailable import UnavailableTelephony

        return UnavailableTelephony()
    return FakeTelephony(clock)


def mask_call_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    telephony: Annotated[TelephonyPort, Depends(telephony_port_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> MaskCall:
    return MaskCall(
        bookings=bookings,
        telephony=telephony,
        enabled=settings.is_masked_call_enabled(),
    )


def manage_notifications_dep(
    notifications: Annotated[NotificationRepository, Depends(notification_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> ManageNotifications:
    return ManageNotifications(notifications=notifications, clock=clock)


def notify_dep(
    sender: Annotated[NotificationSender, Depends(notification_sender_dep)],
    devices: Annotated[DeviceTokenRepository, Depends(device_token_repository_dep)],
    settings: Annotated[Settings, Depends(settings_dep)],
) -> Notify:
    return Notify(sender=sender, devices=devices, sms_enabled=settings.sms_enabled)


def cancel_booking_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    policy: Annotated[BookingPolicy, Depends(booking_policy_dep)],
    wallet: Annotated[WalletService, Depends(wallet_service_dep)],
    notify: Annotated[Notify, Depends(notify_dep)],
) -> CancelBooking:
    return CancelBooking(
        bookings=bookings, clock=clock, policy=policy, wallet=wallet, notify=notify
    )


def transition_booking_dep(
    bookings: Annotated[BookingRepository, Depends(booking_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
    proofs: Annotated[PartsProofRepository, Depends(parts_proof_repository_dep)],
    notify: Annotated[Notify, Depends(notify_dep)],
) -> TransitionBooking:
    return TransitionBooking(bookings=bookings, clock=clock, proofs=proofs, notify=notify)


def register_device_dep(
    devices: Annotated[DeviceTokenRepository, Depends(device_token_repository_dep)],
    clock: Annotated[Clock, Depends(clock_dep)],
) -> RegisterDevice:
    return RegisterDevice(devices=devices, clock=clock)
