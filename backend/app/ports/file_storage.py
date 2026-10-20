from typing import Protocol

from app.domain.storage import SignedDownload, SignedUpload


class FileStorage(Protocol):
    async def signed_upload(self, path: str, content_type: str, max_bytes: int) -> SignedUpload: ...

    async def signed_download(self, path: str) -> SignedDownload: ...

    async def put(self, path: str, data: bytes, content_type: str) -> None: ...
