import re
from dataclasses import dataclass
from uuid import uuid4

from app.domain.contact import EmergencyContact
from app.domain.errors import InvalidInput, NotFound, PermissionDenied
from app.domain.user import Principal, Role
from app.ports.user_repository import UserRepository

MAX_CONTACTS = 3


def normalize_indian_mobile(raw: str) -> str:
    digits = re.sub(r"[^\d+]", "", raw.strip())
    if digits.startswith("+91"):
        digits = digits[3:]
    elif digits.startswith("91") and len(digits) == 12:
        digits = digits[2:]
    if not re.fullmatch(r"[6-9]\d{9}", digits):
        raise InvalidInput("Enter a valid Indian mobile number.")
    return f"+91{digits}"


@dataclass(frozen=True)
class ManageContacts:
    users: UserRepository

    def _ensure_customer(self, principal: Principal) -> None:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")

    async def list_for(self, principal: Principal) -> list[EmergencyContact]:
        self._ensure_customer(principal)
        return await self.users.list_contacts(principal.user_id)

    async def create(self, principal: Principal, *, name: str, phone: str) -> EmergencyContact:
        self._ensure_customer(principal)
        cleaned = name.strip()
        if len(cleaned) < 2 or len(cleaned) > 60:
            raise InvalidInput("Name must be 2 to 60 characters.")
        phone_e164 = normalize_indian_mobile(phone)
        existing = await self.users.list_contacts(principal.user_id)
        if len(existing) >= MAX_CONTACTS:
            raise InvalidInput("You can save up to 3 emergency contacts.")
        if any(item.phone_e164 == phone_e164 for item in existing):
            raise InvalidInput("This number is already saved.")
        contact = EmergencyContact(
            id=str(uuid4()),
            owner_id=principal.user_id,
            name=cleaned,
            phone_e164=phone_e164,
        )
        return await self.users.save_contact(contact)

    async def delete(self, principal: Principal, contact_id: str) -> None:
        self._ensure_customer(principal)
        existing = await self.users.list_contacts(principal.user_id)
        if all(item.id != contact_id for item in existing):
            raise NotFound("We could not find that contact.")
        await self.users.delete_contact(principal.user_id, contact_id)
