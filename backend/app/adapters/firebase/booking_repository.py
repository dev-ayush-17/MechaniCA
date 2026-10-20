from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.domain.booking import (
    AddressSnapshot,
    Booking,
    BookingLine,
    BookingMode,
    LineKind,
    LineStatus,
    PaymentMethod,
    Urgency,
)
from app.domain.booking_state import BookingStatus


def _parse_time(value: object) -> datetime:
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


def _address_to_doc(address: AddressSnapshot) -> dict[str, object]:
    return {
        "id": address.id,
        "label": address.label,
        "line1": address.line1,
        "city": address.city,
        "pincode": address.pincode,
        "lat": address.lat,
        "lng": address.lng,
    }


def _address_from_doc(data: dict[str, object]) -> AddressSnapshot:
    return AddressSnapshot(
        id=str(data["id"]),
        label=str(data["label"]),
        line1=str(data["line1"]),
        city=str(data["city"]),
        pincode=str(data["pincode"]),
        lat=float(str(data["lat"])),
        lng=float(str(data["lng"])),
    )


def _line_to_doc(line: BookingLine) -> dict[str, object]:
    return {
        "id": line.id,
        "kind": line.kind.value,
        "name": line.name,
        "amountPaise": line.amount_paise,
        "gstPaise": line.gst_paise,
        "status": line.status.value,
        "partReplacement": line.part_replacement,
        "createdAt": line.created_at,
    }


def _line_from_doc(data: dict[str, object]) -> BookingLine:
    return BookingLine(
        id=str(data["id"]),
        kind=LineKind(str(data["kind"])),
        name=str(data["name"]),
        amount_paise=int(str(data["amountPaise"])),
        gst_paise=int(str(data["gstPaise"])),
        status=LineStatus(str(data["status"])),
        part_replacement=bool(data.get("partReplacement", False)),
        created_at=_parse_time(data["createdAt"]) if data.get("createdAt") else None,
    )


def _to_doc(booking: Booking) -> dict[str, object]:
    return {
        "displayNumber": booking.display_number,
        "customerId": booking.customer_id,
        "vehicleId": booking.vehicle_id,
        "serviceCode": booking.service_code,
        "serviceName": booking.service_name,
        "mode": booking.mode.value,
        "urgency": booking.urgency.value,
        "status": booking.status.value,
        "paymentMethod": booking.payment_method.value,
        "address": _address_to_doc(booking.address),
        "laborPaise": booking.labor_paise,
        "partsPaise": booking.parts_paise,
        "feePaise": booking.fee_paise,
        "discountPaise": booking.discount_paise,
        "cgstPaise": booking.cgst_paise,
        "sgstPaise": booking.sgst_paise,
        "totalPaise": booking.total_paise,
        "cancelFeePaise": booking.cancel_fee_paise,
        "cancelReason": booking.cancel_reason,
        "scheduledStart": booking.scheduled_start,
        "mechanicId": booking.mechanic_id,
        "lines": [_line_to_doc(line) for line in booking.lines],
        "createdAt": booking.created_at,
        "updatedAt": booking.updated_at,
        "version": booking.version,
        "couponCode": booking.coupon_code,
        "failureReason": booking.failure_reason,
        "dispatchAttempt": booking.dispatch_attempt,
    }


def _from_doc(booking_id: str, data: dict[str, object]) -> Booking:
    address_raw = data.get("address")
    address = _address_from_doc(address_raw if isinstance(address_raw, dict) else {})
    lines_raw = data.get("lines")
    raw_items = lines_raw if isinstance(lines_raw, list) else []
    lines = tuple(_line_from_doc(item) for item in raw_items if isinstance(item, dict))
    return Booking(
        id=booking_id,
        display_number=str(data["displayNumber"]),
        customer_id=str(data["customerId"]),
        vehicle_id=str(data["vehicleId"]),
        service_code=str(data["serviceCode"]),
        service_name=str(data["serviceName"]),
        mode=BookingMode(str(data["mode"])),
        urgency=Urgency(str(data["urgency"])),
        status=BookingStatus(str(data["status"])),
        payment_method=PaymentMethod(str(data["paymentMethod"])),
        address=address,
        labor_paise=int(str(data["laborPaise"])),
        parts_paise=int(str(data["partsPaise"])),
        fee_paise=int(str(data["feePaise"])),
        discount_paise=int(str(data["discountPaise"])),
        cgst_paise=int(str(data["cgstPaise"])),
        sgst_paise=int(str(data["sgstPaise"])),
        total_paise=int(str(data["totalPaise"])),
        cancel_fee_paise=int(str(data.get("cancelFeePaise", 0))),
        cancel_reason=str(data["cancelReason"]) if data.get("cancelReason") else None,
        scheduled_start=_parse_time(data["scheduledStart"]) if data.get("scheduledStart") else None,
        mechanic_id=str(data["mechanicId"]) if data.get("mechanicId") else None,
        lines=lines,
        created_at=_parse_time(data["createdAt"]),
        updated_at=_parse_time(data["updatedAt"]),
        version=int(str(data.get("version", 1))),
        coupon_code=str(data.get("couponCode") or ""),
        failure_reason=str(data["failureReason"]) if data.get("failureReason") else None,
        dispatch_attempt=int(str(data.get("dispatchAttempt", 0))),
    )


class FirestoreBookingRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self) -> Any:
        return self._db.collection("bookings")

    async def get(self, booking_id: str) -> Booking | None:
        snap = self._col().document(booking_id).get()
        if not snap.exists:
            return None
        return _from_doc(snap.id, snap.to_dict() or {})

    async def save(self, booking: Booking) -> Booking:
        self._col().document(booking.id).set(_to_doc(booking))
        return booking

    async def list_by_customer(self, customer_id: str) -> list[Booking]:
        snaps = self._col().where("customerId", "==", customer_id).stream()
        return [_from_doc(s.id, s.to_dict() or {}) for s in snaps]

    async def list_by_mechanic(self, mechanic_id: str) -> list[Booking]:
        snaps = self._col().where("mechanicId", "==", mechanic_id).stream()
        return [_from_doc(s.id, s.to_dict() or {}) for s in snaps]

    async def list_by_status(self, status: BookingStatus) -> list[Booking]:
        snaps = self._col().where("status", "==", status.value).stream()
        return [_from_doc(s.id, s.to_dict() or {}) for s in snaps]

    async def list_all(self) -> list[Booking]:
        return [_from_doc(s.id, s.to_dict() or {}) for s in self._col().stream()]
