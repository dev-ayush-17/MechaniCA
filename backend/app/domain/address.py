from dataclasses import dataclass

from app.domain.booking import AddressSnapshot


@dataclass(frozen=True)
class Address:
    id: str
    owner_id: str
    label: str
    line1: str
    city: str
    pincode: str
    lat: float
    lng: float
    is_default: bool
    landmark: str | None = None

    def snapshot(self) -> AddressSnapshot:
        return AddressSnapshot(
            id=self.id,
            label=self.label,
            line1=self.line1,
            city=self.city,
            pincode=self.pincode,
            lat=self.lat,
            lng=self.lng,
        )
