from dataclasses import dataclass
from datetime import datetime
from uuid import uuid4

from app.application.refund_payment import RefundPayment
from app.domain.audit import AuditEvent
from app.domain.booking_state import BookingStatus, actor_for, assert_transition
from app.domain.dispute import Dispute, DisputeNote, DisputeResolution, DisputeStatus
from app.domain.errors import Conflict, InvalidInput, NotFound, PermissionDenied
from app.domain.user import Principal, Role
from app.domain.wallet import LedgerDirection, LedgerEntry, LedgerReason
from app.ports.audit_log import AuditLog
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.dispute_repository import DisputeRepository
from app.ports.payment_repository import PaymentRepository
from app.ports.wallet_service import WalletService

_DISPUTE_FROM = frozenset(
    {
        BookingStatus.ARRIVED,
        BookingStatus.IN_SERVICE,
        BookingStatus.COMPLETED,
        BookingStatus.PAID,
    }
)
_STAFF = frozenset({Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN})
_ADMIN = frozenset({Role.ADMIN, Role.SUPER_ADMIN})


def _audit(
    principal: Principal,
    *,
    action: str,
    target_id: str,
    summary: str,
    request_id: str,
    now: datetime,
) -> AuditEvent:
    return AuditEvent(
        id=uuid4().hex,
        actor_id=principal.user_id,
        role=principal.role.value,
        action=action,
        target_type="dispute",
        target_id=target_id,
        summary=summary,
        request_id=request_id,
        created_at=now,
    )


@dataclass(frozen=True)
class OpenDispute:
    disputes: DisputeRepository
    bookings: BookingRepository
    clock: Clock
    audit: AuditLog

    async def execute(
        self, principal: Principal, booking_id: str, *, reason: str, request_id: str
    ) -> Dispute:
        cleaned = reason.strip()
        if not cleaned:
            raise InvalidInput("Add a reason.", fields={"reason": "required"})
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        if principal.role is Role.CUSTOMER and booking.customer_id != principal.user_id:
            raise PermissionDenied("This booking is not yours.")
        if principal.role is Role.CUSTOMER or principal.role in _STAFF:
            pass
        else:
            raise PermissionDenied("Only the customer or staff can open a dispute.")
        existing = await self.disputes.open_for_booking(booking.id)
        if existing is not None:
            raise Conflict("A dispute is already open for this booking.")
        if booking.status not in _DISPUTE_FROM and booking.status is not BookingStatus.DISPUTED:
            raise InvalidInput("A dispute can be opened after the mechanic has arrived.")
        now = self.clock.now()
        dispute = Dispute(
            id=uuid4().hex,
            booking_id=booking.id,
            customer_id=booking.customer_id,
            reason=cleaned,
            status=DisputeStatus.OPEN,
            notes=(),
            resolution=None,
            resolution_amount_paise=0,
            resolution_note="",
            created_at=now,
            updated_at=now,
        )
        saved = await self.disputes.open(dispute)
        if booking.status is not BookingStatus.DISPUTED:
            assert_transition(booking.status, BookingStatus.DISPUTED, actor_for(principal.role))
            await self.bookings.save(booking.with_status(BookingStatus.DISPUTED, now=now))
        await self.audit.append(
            _audit(
                principal,
                action="dispute_open",
                target_id=saved.id,
                summary=cleaned,
                request_id=request_id,
                now=now,
            )
        )
        return saved


@dataclass(frozen=True)
class AddDisputeNote:
    disputes: DisputeRepository
    clock: Clock
    audit: AuditLog

    async def execute(
        self, principal: Principal, dispute_id: str, *, note: str, request_id: str
    ) -> Dispute:
        if principal.role not in _STAFF:
            raise PermissionDenied("Staff access required.")
        cleaned = note.strip()
        if not cleaned:
            raise InvalidInput("Add a note.", fields={"note": "required"})
        dispute = await self.disputes.get(dispute_id)
        if dispute is None:
            raise NotFound("We could not find that dispute.")
        if dispute.status is not DisputeStatus.OPEN:
            raise InvalidInput("This dispute is already resolved.")
        now = self.clock.now()
        saved = await self.disputes.save(
            dispute.with_note(DisputeNote(principal.user_id, cleaned, now), now=now)
        )
        await self.audit.append(
            _audit(
                principal,
                action="dispute_note",
                target_id=saved.id,
                summary=cleaned,
                request_id=request_id,
                now=now,
            )
        )
        return saved


@dataclass(frozen=True)
class ResolveDispute:
    disputes: DisputeRepository
    payments: PaymentRepository
    wallet: WalletService
    refunds: RefundPayment
    clock: Clock
    audit: AuditLog

    async def execute(
        self,
        principal: Principal,
        dispute_id: str,
        *,
        resolution: DisputeResolution,
        amount_paise: int,
        note: str,
        request_id: str,
        idempotency_key: str | None,
    ) -> Dispute:
        if principal.role not in _ADMIN:
            await self.audit.append(
                _audit(
                    principal,
                    action="dispute_resolve_denied",
                    target_id=dispute_id,
                    summary="Support cannot resolve a dispute.",
                    request_id=request_id,
                    now=self.clock.now(),
                )
            )
            raise PermissionDenied("Admin access required.")
        cleaned = note.strip()
        if not cleaned:
            raise InvalidInput("Add a resolution note.", fields={"note": "required"})
        if amount_paise < 0:
            raise InvalidInput("Amount cannot be negative.")
        if resolution is DisputeResolution.REFUND and amount_paise <= 0:
            raise InvalidInput("Refund amount must be greater than zero.")
        dispute = await self.disputes.get(dispute_id)
        if dispute is None:
            raise NotFound("We could not find that dispute.")
        if dispute.status is not DisputeStatus.OPEN:
            raise InvalidInput("This dispute is already resolved.")
        now = self.clock.now()
        if resolution is DisputeResolution.REFUND:
            payment = await self.payments.get_by_booking(dispute.booking_id)
            if payment is None:
                raise NotFound("We could not find a payment for this booking.")
            await self.refunds.execute(
                principal,
                payment_id=payment.id,
                amount_paise=amount_paise,
                idempotency_key=idempotency_key,
                request_id=request_id,
            )
        elif resolution is DisputeResolution.CASH_WALLET_CREDIT:
            if amount_paise <= 0:
                raise InvalidInput("Credit amount must be greater than zero.")
            await self.wallet.credit(
                dispute.customer_id,
                LedgerEntry(
                    id=f"dispute_{dispute.id}",
                    user_id=dispute.customer_id,
                    booking_id=dispute.booking_id,
                    direction=LedgerDirection.CREDIT,
                    amount_paise=amount_paise,
                    reason=LedgerReason.ADJUSTMENT,
                    created_at=now,
                ),
            )
        saved = await self.disputes.save(
            dispute.resolved(
                resolution=resolution, amount_paise=amount_paise, note=cleaned, now=now
            )
        )
        await self.audit.append(
            _audit(
                principal,
                action="dispute_resolve",
                target_id=saved.id,
                summary=f"{resolution.value}: {cleaned}",
                request_id=request_id,
                now=now,
            )
        )
        return saved
