import logging
import uuid
from dataclasses import dataclass
from datetime import timedelta

from app.domain.booking import Booking, BookingLine, LineKind, LineStatus
from app.domain.booking_state import BookingStatus
from app.domain.catalog import BPS_DENOMINATOR
from app.domain.dispatch import DispatchConfig
from app.domain.errors import InvalidInput, InvalidTransition, NotFound, PermissionDenied
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.job_scheduler import JobScheduler, ScheduledJob

_LOG = logging.getLogger("mechupp.extra_line")


@dataclass(frozen=True)
class AddExtraLine:
    """Mechanic adds a pending extra line and schedules the 10-minute timeout."""

    bookings: BookingRepository
    clock: Clock
    gst_bps: int
    scheduler: JobScheduler | None = None

    async def execute(
        self,
        principal: Principal,
        booking_id: str,
        *,
        name: str,
        amount_paise: int,
        kind: LineKind = LineKind.PART,
    ) -> Booking:
        if principal.role != Role.MECHANIC:
            raise PermissionDenied("Mechanic account required.")
        if amount_paise <= 0:
            raise InvalidInput("Amount must be greater than zero.")
        label = name.strip()
        if not label:
            raise InvalidInput("Name the extra item.")
        booking = await self._load(booking_id)
        if booking.status is not BookingStatus.IN_SERVICE:
            raise InvalidTransition(
                "Extra work can only be added while the service is in progress."
            )
        if booking.mechanic_id not in {None, principal.user_id}:
            raise PermissionDenied("You are not assigned to this booking.")
        gst = amount_paise * self.gst_bps // BPS_DENOMINATOR
        line = BookingLine(
            id=str(uuid.uuid4()),
            kind=kind,
            name=label,
            amount_paise=amount_paise,
            gst_paise=gst,
            status=LineStatus.PENDING_APPROVAL,
            part_replacement=kind is LineKind.PART,
            created_at=self.clock.now(),
        )
        updated = booking.with_lines((*booking.lines, line), now=self.clock.now())
        saved = await self.bookings.save(updated)
        await self._schedule_timeout(saved.id, line.id)
        return saved

    async def _schedule_timeout(self, booking_id: str, line_id: str) -> None:
        if self.scheduler is None:
            return
        delay = timedelta(seconds=DispatchConfig().extra_work_timeout_seconds)
        try:
            await self.scheduler.schedule(
                ScheduledJob(
                    id=f"extra-line-{line_id}",
                    run_at=self.clock.now() + delay,
                    target_path="/v1/internal/jobs/extra-work-timeout",
                    body={"bookingId": booking_id, "lineId": line_id},
                )
            )
        except Exception as exc:
            _LOG.warning(
                "schedule_failed",
                extra={"fields": {"lineId": line_id, "error": type(exc).__name__}},
            )

    async def _load(self, booking_id: str) -> Booking:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        return booking


@dataclass(frozen=True)
class DecideExtraLine:
    """Customer approves or rejects a pending extra line."""

    bookings: BookingRepository
    clock: Clock

    async def execute(
        self,
        principal: Principal,
        booking_id: str,
        line_id: str,
        *,
        approve: bool,
    ) -> Booking:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        if booking.customer_id != principal.user_id:
            raise PermissionDenied("You do not have access to that booking.")
        found = next((line for line in booking.lines if line.id == line_id), None)
        if found is None:
            raise NotFound("We could not find that line.")
        if found.status is not LineStatus.PENDING_APPROVAL:
            raise InvalidTransition("This extra item was already decided.")
        updated_line = BookingLine(
            id=found.id,
            kind=found.kind,
            name=found.name,
            amount_paise=found.amount_paise,
            gst_paise=found.gst_paise,
            status=LineStatus.APPROVED if approve else LineStatus.REJECTED,
            part_replacement=found.part_replacement,
            created_at=found.created_at,
        )
        lines = tuple(updated_line if line.id == line_id else line for line in booking.lines)
        changed = booking.with_lines(lines, now=self.clock.now())
        if approve:
            from dataclasses import replace

            changed = replace(
                changed,
                parts_paise=changed.parts_paise + found.amount_paise,
                total_paise=changed.total_paise + found.amount_paise + found.gst_paise,
            )
        return await self.bookings.save(changed)
