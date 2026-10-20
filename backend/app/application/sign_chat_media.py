import uuid
from dataclasses import dataclass

from app.domain.errors import InvalidInput, NotFound
from app.domain.storage import SignedUpload
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.file_storage import FileStorage

_ALLOWED = frozenset({"image/jpeg", "image/png"})
_MAX_BYTES = 5 * 1024 * 1024
_EXT = {"image/jpeg": "jpg", "image/png": "png"}


@dataclass(frozen=True)
class SignChatMedia:
    """Reuses FileStorage. Callers must not invent a second storage port."""

    storage: FileStorage
    bookings: BookingRepository

    async def execute(
        self,
        principal: Principal,
        booking_id: str,
        *,
        content_type: str,
        max_bytes: int,
    ) -> SignedUpload:
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        is_party = principal.user_id in {booking.customer_id, booking.mechanic_id}
        is_staff = principal.role in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}
        if not is_party and not is_staff:
            raise NotFound("We could not find that booking.")
        if content_type not in _ALLOWED:
            raise InvalidInput("Use JPEG or PNG.", fields={"contentType": "invalid"})
        if max_bytes <= 0 or max_bytes > _MAX_BYTES:
            raise InvalidInput("File is too large.", fields={"maxBytes": "invalid"})
        ext = _EXT[content_type]
        path = f"chat/{booking_id}/{uuid.uuid4()}.{ext}"
        return await self.storage.signed_upload(path, content_type, max_bytes)
