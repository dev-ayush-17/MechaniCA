from typing import Any

from firebase_admin import firestore

from app.adapters.fake.address_repository import PATNA_HOME
from app.domain.address import Address
from app.domain.booking import AddressSnapshot


def address_to_doc(address: Address) -> dict[str, object]:
    return {
        "ownerId": address.owner_id,
        "label": address.label,
        "line1": address.line1,
        "city": address.city,
        "pincode": address.pincode,
        "lat": address.lat,
        "lng": address.lng,
        "isDefault": address.is_default,
        "landmark": address.landmark,
    }


def address_from_doc(address_id: str, data: dict[str, object]) -> Address:
    return Address(
        id=address_id,
        owner_id=str(data["ownerId"]),
        label=str(data["label"]),
        line1=str(data["line1"]),
        city=str(data["city"]),
        pincode=str(data["pincode"]),
        lat=float(str(data["lat"])),
        lng=float(str(data["lng"])),
        is_default=bool(data.get("isDefault", False)),
        landmark=str(data["landmark"]) if data.get("landmark") else None,
    )


class FirestoreAddressRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _col(self, owner_id: str) -> Any:
        return self._db.collection("users").document(owner_id).collection("addresses")

    async def get(self, owner_id: str, address_id: str) -> AddressSnapshot | None:
        snap = self._col(owner_id).document(address_id).get()
        if not snap.exists:
            if address_id == PATNA_HOME.id:
                return PATNA_HOME
            return None
        return address_from_doc(snap.id, snap.to_dict() or {}).snapshot()

    async def list(self, owner_id: str) -> list[Address]:
        return [address_from_doc(s.id, s.to_dict() or {}) for s in self._col(owner_id).stream()]

    async def save(self, address: Address) -> Address:
        self._col(address.owner_id).document(address.id).set(address_to_doc(address))
        return address

    async def delete(self, owner_id: str, address_id: str) -> None:
        self._col(owner_id).document(address_id).delete()
