from datetime import datetime
from typing import Any

from firebase_admin import firestore

from app.domain.contact import EmergencyContact
from app.domain.user import Role, User, UserStatus


def _parse_time(value: object) -> datetime:
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


def user_to_doc(user: User) -> dict[str, object]:
    return {
        "role": user.role.value,
        "name": user.name,
        "phoneE164": user.phone_e164,
        "status": user.status.value,
        "authProvider": user.auth_provider,
        "authSubject": user.auth_subject,
        "createdAt": user.created_at,
        "updatedAt": user.updated_at,
        "email": user.email,
        "photoPath": user.photo_path,
    }


def user_from_doc(user_id: str, data: dict[str, object]) -> User:
    return User(
        id=user_id,
        role=Role(str(data.get("role", Role.CUSTOMER.value))),
        name=str(data.get("name", "")),
        phone_e164=str(data.get("phoneE164", "")),
        status=UserStatus(str(data.get("status", UserStatus.ACTIVE.value))),
        auth_provider=str(data.get("authProvider", "fake")),
        auth_subject=str(data.get("authSubject", user_id)),
        created_at=_parse_time(data["createdAt"]),
        updated_at=_parse_time(data["updatedAt"]),
        email=str(data["email"]) if data.get("email") else None,
        photo_path=str(data["photoPath"]) if data.get("photoPath") else None,
    )


def contact_to_doc(contact: EmergencyContact) -> dict[str, object]:
    return {
        "ownerId": contact.owner_id,
        "name": contact.name,
        "phoneE164": contact.phone_e164,
    }


def contact_from_doc(contact_id: str, data: dict[str, object]) -> EmergencyContact:
    return EmergencyContact(
        id=contact_id,
        owner_id=str(data["ownerId"]),
        name=str(data["name"]),
        phone_e164=str(data["phoneE164"]),
    )


class FirestoreUserRepository:
    def __init__(self, _project_id: str) -> None:
        self._db = firestore.client()

    def _user_ref(self, user_id: str) -> Any:
        return self._db.collection("users").document(user_id)

    def _contacts(self, owner_id: str) -> Any:
        return self._user_ref(owner_id).collection("contacts")

    async def get(self, user_id: str) -> User | None:
        snap = self._user_ref(user_id).get()
        if not snap.exists:
            return None
        return user_from_doc(snap.id, snap.to_dict() or {})

    async def upsert(self, user: User) -> User:
        self._user_ref(user.id).set(user_to_doc(user), merge=True)
        return user

    async def search(self, query: str) -> list[User]:
        needle = query.strip().lower()
        users = [
            user_from_doc(s.id, s.to_dict() or {})
            for s in self._db.collection("users").stream()
        ]
        if not needle:
            return users
        return [
            user
            for user in users
            if needle in user.name.lower() or needle in user.phone_e164
        ]

    async def list_contacts(self, owner_id: str) -> list[EmergencyContact]:
        return [
            contact_from_doc(s.id, s.to_dict() or {})
            for s in self._contacts(owner_id).stream()
        ]

    async def save_contact(self, contact: EmergencyContact) -> EmergencyContact:
        self._contacts(contact.owner_id).document(contact.id).set(contact_to_doc(contact))
        return contact

    async def delete_contact(self, owner_id: str, contact_id: str) -> None:
        self._contacts(owner_id).document(contact_id).delete()
