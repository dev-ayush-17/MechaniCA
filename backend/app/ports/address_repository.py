from typing import Protocol

from app.domain.address import Address
from app.domain.booking import AddressSnapshot


class AddressRepository(Protocol):
    """Saved addresses for a customer."""

    async def get(self, owner_id: str, address_id: str) -> AddressSnapshot | None: ...

    async def list(self, owner_id: str) -> list[Address]: ...

    async def save(self, address: Address) -> Address: ...

    async def delete(self, owner_id: str, address_id: str) -> None: ...
