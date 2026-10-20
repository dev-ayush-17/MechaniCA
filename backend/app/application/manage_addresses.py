import re
from dataclasses import dataclass, replace
from uuid import uuid4

from app.domain.address import Address
from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.user import Principal, Role
from app.ports.address_repository import AddressRepository

MAX_ADDRESSES = 10
_PIN = re.compile(r"^\d{6}$")


@dataclass(frozen=True)
class ManageAddresses:
    addresses: AddressRepository

    def _ensure_customer(self, principal: Principal) -> None:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")

    async def list_for(self, principal: Principal) -> list[Address]:
        self._ensure_customer(principal)
        return await self.addresses.list(principal.user_id)

    async def create(
        self,
        principal: Principal,
        *,
        label: str,
        line1: str,
        city: str,
        pincode: str,
        lat: float,
        lng: float,
        landmark: str | None,
        is_default: bool,
    ) -> Address:
        self._ensure_customer(principal)
        self._validate(
            label=label, line1=line1, city=city, pincode=pincode, lat=lat, lng=lng
        )
        existing = await self.addresses.list(principal.user_id)
        if len(existing) >= MAX_ADDRESSES:
            raise InvalidInput("You can save up to 10 addresses.")
        make_default = is_default or not existing
        if make_default:
            await self._clear_defaults(existing)
        address = Address(
            id=str(uuid4()),
            owner_id=principal.user_id,
            label=label.strip(),
            line1=line1.strip(),
            city=city.strip(),
            pincode=pincode.strip(),
            lat=lat,
            lng=lng,
            is_default=make_default,
            landmark=landmark.strip() if landmark else None,
        )
        return await self.addresses.save(address)

    async def update(
        self,
        principal: Principal,
        address_id: str,
        *,
        label: str | None,
        line1: str | None,
        city: str | None,
        pincode: str | None,
        lat: float | None,
        lng: float | None,
        landmark: str | None,
        is_default: bool | None,
    ) -> Address:
        self._ensure_customer(principal)
        current = await self._get(principal.user_id, address_id)
        next_label = label.strip() if label is not None else current.label
        next_line1 = line1.strip() if line1 is not None else current.line1
        next_city = city.strip() if city is not None else current.city
        next_pin = pincode.strip() if pincode is not None else current.pincode
        next_lat = current.lat if lat is None else lat
        next_lng = current.lng if lng is None else lng
        self._validate(
            label=next_label,
            line1=next_line1,
            city=next_city,
            pincode=next_pin,
            lat=next_lat,
            lng=next_lng,
        )
        make_default = current.is_default if is_default is None else is_default
        if make_default and not current.is_default:
            await self._clear_defaults(await self.addresses.list(principal.user_id))
        updated = replace(
            current,
            label=next_label,
            line1=next_line1,
            city=next_city,
            pincode=next_pin,
            lat=next_lat,
            lng=next_lng,
            is_default=make_default,
            landmark=current.landmark if landmark is None else (landmark.strip() or None),
        )
        return await self.addresses.save(updated)

    async def delete(self, principal: Principal, address_id: str) -> None:
        self._ensure_customer(principal)
        await self._get(principal.user_id, address_id)
        await self.addresses.delete(principal.user_id, address_id)

    async def _get(self, owner_id: str, address_id: str) -> Address:
        for item in await self.addresses.list(owner_id):
            if item.id == address_id:
                return item
        raise NotFound("We could not find that address.")

    async def _clear_defaults(self, existing: list[Address]) -> None:
        for item in existing:
            if item.is_default:
                await self.addresses.save(replace(item, is_default=False))

    def _validate(
        self,
        *,
        label: str,
        line1: str,
        city: str,
        pincode: str,
        lat: float,
        lng: float,
    ) -> None:
        if not label.strip() or len(label.strip()) > 40:
            raise InvalidInput("Enter an address label.")
        if len(line1.strip()) < 4:
            raise InvalidInput("Enter the address line.")
        if not city.strip():
            raise InvalidInput("Enter a city.")
        if not _PIN.fullmatch(pincode.strip()):
            raise InvalidInput("Enter a 6-digit PIN code.")
        if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
            raise InvalidInput("Pick a point on the map.")
