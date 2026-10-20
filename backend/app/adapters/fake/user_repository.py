from app.domain.contact import EmergencyContact
from app.domain.user import User


class FakeUserRepository:
    """In-memory users collection. Process-local; a restart forgets everything."""

    def __init__(self) -> None:
        self._users: dict[str, User] = {}
        self._contacts: dict[str, dict[str, EmergencyContact]] = {}

    async def get(self, user_id: str) -> User | None:
        return self._users.get(user_id)

    async def upsert(self, user: User) -> User:
        self._users[user.id] = user
        return user

    async def search(self, query: str) -> list[User]:
        needle = query.strip().lower()
        if not needle:
            return list(self._users.values())
        return [
            user
            for user in self._users.values()
            if needle in user.name.lower() or needle in user.phone_e164
        ]

    async def list_contacts(self, owner_id: str) -> list[EmergencyContact]:
        return list(self._contacts.get(owner_id, {}).values())

    async def save_contact(self, contact: EmergencyContact) -> EmergencyContact:
        bucket = self._contacts.setdefault(contact.owner_id, {})
        bucket[contact.id] = contact
        return contact

    async def delete_contact(self, owner_id: str, contact_id: str) -> None:
        self._contacts.get(owner_id, {}).pop(contact_id, None)
