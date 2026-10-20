from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Header, Request
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import (
    add_extra_line_dep,
    cancel_booking_dep,
    create_booking_dep,
    decide_extra_line_dep,
    get_booking_dep,
    open_dispute_dep,
    principal_dep,
    transition_booking_dep,
)
from app.api.errors import REQUEST_ID_HEADER, error_responses
from app.api.v1.admin import DisputeOut
from app.application.cancel_booking import CancelBooking
from app.application.create_booking import CreateBooking
from app.application.disputes import OpenDispute
from app.application.extra_line import AddExtraLine, DecideExtraLine
from app.application.get_booking import GetBooking
from app.application.transition_booking import TransitionBooking
from app.domain.booking import Booking, BookingLine, BookingMode, LineKind, PaymentMethod, Urgency
from app.domain.booking_state import BookingStatus
from app.domain.user import Principal

router = APIRouter(
    prefix="/v1/bookings",
    tags=["bookings"],
    responses=error_responses(400, 401, 403, 404, 409),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class EstimateOut(_Camel):
    labor_paise: int
    parts_paise: int
    fee_paise: int
    discount_paise: int
    cgst_paise: int
    sgst_paise: int
    total_paise: int


class BookingCreateOut(_Camel):
    id: str
    status: str
    display_number: str
    estimate: EstimateOut
    version: int
    cancel_fee_paise: int = 0
    urgency: str
    mode: str
    service_code: str


class BookingLineOut(_Camel):
    id: str
    kind: str
    name: str
    amount_paise: int
    gst_paise: int
    status: str

    @classmethod
    def of(cls, line: BookingLine) -> "BookingLineOut":
        return cls(
            id=line.id,
            kind=line.kind.value,
            name=line.name,
            amount_paise=line.amount_paise,
            gst_paise=line.gst_paise,
            status=line.status.value,
        )


class BookingOut(BookingCreateOut):
    vehicle_id: str
    service_name: str
    payment_method: str
    address_id: str
    mechanic_id: str | None
    scheduled_start: datetime | None
    cancel_reason: str | None
    failure_reason: str | None = None
    dispatch_attempt: int = 0
    lines: list[BookingLineOut]


class BookingListOut(_Camel):
    items: list[BookingOut]


class CreateBookingRequest(_Camel):
    vehicle_id: str
    service_code: str
    address_id: str
    mode: BookingMode
    urgency: Urgency = Urgency.NORMAL
    payment_method: PaymentMethod
    coupon_code: str = ""
    scheduled_start: datetime | None = None


class CancelBookingRequest(_Camel):
    reason: str = "Cancelled"


class TransitionRequest(_Camel):
    to: BookingStatus
    expected_version: int | None = None


class AddLineRequest(_Camel):
    name: str
    amount_paise: int
    kind: LineKind = LineKind.PART


class LineDecisionRequest(_Camel):
    decision: Literal["approve", "reject"]


def _estimate(booking: Booking) -> EstimateOut:
    return EstimateOut(
        labor_paise=booking.labor_paise,
        parts_paise=booking.parts_paise,
        fee_paise=booking.fee_paise,
        discount_paise=booking.discount_paise,
        cgst_paise=booking.cgst_paise,
        sgst_paise=booking.sgst_paise,
        total_paise=booking.total_paise,
    )


def _create_out(booking: Booking) -> BookingCreateOut:
    return BookingCreateOut(
        id=booking.id,
        status=booking.status.value,
        display_number=booking.display_number,
        estimate=_estimate(booking),
        version=booking.version,
        cancel_fee_paise=booking.cancel_fee_paise,
        urgency=booking.urgency.value,
        mode=booking.mode.value,
        service_code=booking.service_code,
    )


def _out(booking: Booking) -> BookingOut:
    return BookingOut(
        **_create_out(booking).model_dump(),
        vehicle_id=booking.vehicle_id,
        service_name=booking.service_name,
        payment_method=booking.payment_method.value,
        address_id=booking.address.id,
        mechanic_id=booking.mechanic_id,
        scheduled_start=booking.scheduled_start,
        cancel_reason=booking.cancel_reason,
        failure_reason=booking.failure_reason,
        dispatch_attempt=booking.dispatch_attempt,
        lines=[BookingLineOut.of(line) for line in booking.lines],
    )


@router.post("", response_model=BookingCreateOut, status_code=201)
async def create_booking(
    body: CreateBookingRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[CreateBooking, Depends(create_booking_dep)],
    idempotency_key: Annotated[str | None, Header()] = None,
) -> BookingCreateOut:
    booking = await use_case.execute(
        principal,
        idempotency_key=idempotency_key,
        vehicle_id=body.vehicle_id,
        service_code=body.service_code,
        address_id=body.address_id,
        mode=body.mode,
        urgency=body.urgency,
        payment_method=body.payment_method,
        coupon_code=body.coupon_code,
        scheduled_start=body.scheduled_start,
    )
    return _create_out(booking)


@router.get("", response_model=BookingListOut)
async def list_bookings(
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[GetBooking, Depends(get_booking_dep)],
) -> BookingListOut:
    return BookingListOut(items=[_out(item) for item in await use_case.list_mine(principal)])


@router.get("/{booking_id}", response_model=BookingOut)
async def get_booking(
    booking_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[GetBooking, Depends(get_booking_dep)],
) -> BookingOut:
    return _out(await use_case.execute(principal, booking_id))


@router.post("/{booking_id}/cancel", response_model=BookingOut)
async def cancel_booking(
    booking_id: str,
    body: CancelBookingRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[CancelBooking, Depends(cancel_booking_dep)],
) -> BookingOut:
    return _out(await use_case.execute(principal, booking_id, reason=body.reason))


@router.post("/{booking_id}/transitions", response_model=BookingOut)
async def transition_booking(
    booking_id: str,
    body: TransitionRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[TransitionBooking, Depends(transition_booking_dep)],
) -> BookingOut:
    return _out(
        await use_case.execute(
            principal,
            booking_id,
            target=body.to,
            expected_version=body.expected_version,
        )
    )


@router.post("/{booking_id}/lines", response_model=BookingOut, status_code=201)
async def add_extra_line(
    booking_id: str,
    body: AddLineRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[AddExtraLine, Depends(add_extra_line_dep)],
) -> BookingOut:
    return _out(
        await use_case.execute(
            principal,
            booking_id,
            name=body.name,
            amount_paise=body.amount_paise,
            kind=body.kind,
        )
    )


class OpenDisputeRequest(_Camel):
    reason: str


@router.post("/{booking_id}/disputes", response_model=DisputeOut, status_code=201)
async def open_booking_dispute(
    booking_id: str,
    body: OpenDisputeRequest,
    request: Request,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[OpenDispute, Depends(open_dispute_dep)],
) -> DisputeOut:
    request_id = request.headers.get(REQUEST_ID_HEADER, getattr(request.state, "request_id", ""))
    opened = await use_case.execute(
        principal, booking_id, reason=body.reason, request_id=str(request_id)
    )
    return DisputeOut.of(opened)


@router.post("/{booking_id}/lines/{line_id}/decision", response_model=BookingOut)
async def decide_extra_line(
    booking_id: str,
    line_id: str,
    body: LineDecisionRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[DecideExtraLine, Depends(decide_extra_line_dep)],
) -> BookingOut:
    return _out(
        await use_case.execute(
            principal,
            booking_id,
            line_id,
            approve=body.decision == "approve",
        )
    )
