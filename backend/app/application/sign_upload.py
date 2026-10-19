from dataclasses import dataclass

from app.domain.errors import InvalidInput, PermissionDenied
from app.domain.storage import SignedUpload
from app.domain.user import Principal, Role
from app.ports.file_storage import FileStorage


_ALLOWED_TYPES = frozenset(
    {"image/jpeg", "image/png", "application/pdf"},
)
_MAX_BYTES = 5 * 1024 * 1024


@dataclass(frozen=True)
class SignUpload:
    storage: FileStorage

    async def execute(
        self,
        principal: Principal,
        *,
        path: str,
        content_type: str,
        max_bytes: int,
    ) -> SignedUpload:
        if principal.role not in (Role.CUSTOMER, Role.MECHANIC, Role.ADMIN, Role.SUPER_ADMIN):
            raise PermissionDenied("You cannot upload here.")
        if content_type not in _ALLOWED_TYPES:
            raise InvalidInput("Use JPEG, PNG, or PDF.", fields={"contentType": "invalid"})
        if max_bytes <= 0 or max_bytes > _MAX_BYTES:
            raise InvalidInput("File is too large.", fields={"maxBytes": "invalid"})
        if not path.startswith(f"mechanicDocs/{principal.user_id}/"):
            raise PermissionDenied("You can only upload your own documents.")
        return await self.storage.signed_upload(path, content_type, max_bytes)
