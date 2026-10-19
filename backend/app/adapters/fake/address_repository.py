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
        self._items: dict[tuple[str, str], AddressSnapshot] = {}

    def seed(self, owner_id: str, address: AddressSnapshot) -> None:
        self._items[(owner_id, address.id)] = address

    async def get(self, owner_id: str, address_id: str) -> AddressSnapshot | None:
        found = self._items.get((owner_id, address_id))
        if found is not None:
            return found
        if address_id == PATNA_HOME.id:
            return PATNA_HOME
        return None
