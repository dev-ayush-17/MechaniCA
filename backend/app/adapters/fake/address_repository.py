from app.domain.address import Address
from app.domain.booking import AddressSnapshot

# Demo / test default inside the Patna service area.
PATNA_HOME = AddressSnapshot(
    id="addr_home",
    label="Home",
    line1="Rajendra Nagar",
    city="Patna",
    pincode="800001",
    lat=25.5941,
    lng=85.1376,
)


class FakeAddressRepository:
    """In-memory addresses. `addr_home` resolves for any owner so the wizard can submit."""

    def __init__(self) -> None:
        self._items: dict[tuple[str, str], Address] = {}

    def seed(self, owner_id: str, address: Address | AddressSnapshot) -> None:
        if isinstance(address, AddressSnapshot):
            stored = Address(
                id=address.id,
                owner_id=owner_id,
                label=address.label,
                line1=address.line1,
                city=address.city,
                pincode=address.pincode,
                lat=address.lat,
                lng=address.lng,
                is_default=address.id == PATNA_HOME.id,
            )
        else:
            stored = address
        self._items[(owner_id, stored.id)] = stored

    async def get(self, owner_id: str, address_id: str) -> AddressSnapshot | None:
        found = self._items.get((owner_id, address_id))
        if found is not None:
            return found.snapshot()
        if address_id == PATNA_HOME.id:
            return PATNA_HOME
        return None

    async def list(self, owner_id: str) -> list[Address]:
        return [item for (oid, _), item in self._items.items() if oid == owner_id]

    async def save(self, address: Address) -> Address:
        self._items[(address.owner_id, address.id)] = address
        return address

    async def delete(self, owner_id: str, address_id: str) -> None:
        self._items.pop((owner_id, address_id), None)
