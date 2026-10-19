from typing import Protocol

from app.domain.booking import AddressSnapshot


class AddressRepository(Protocol):
    """Saved addresses for a customer. M06 reads only; the address API lands later."""

    async def get(self, owner_id: str, address_id: str) -> AddressSnapshot | None: ...
