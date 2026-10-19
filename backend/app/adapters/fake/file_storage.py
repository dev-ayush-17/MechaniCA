from app.domain.errors import InvalidInput
from app.domain.storage import SignedDownload, SignedUpload


class FakeFileStorage:
    """Returns deterministic fake URLs for tests and dev without Cloud Storage."""

    async def signed_upload(self, path: str, content_type: str, max_bytes: int) -> SignedUpload:
        if ".." in path or path.startswith("/"):
            raise InvalidInput("That path is not allowed.", fields={"path": "invalid"})
        if max_bytes <= 0 or max_bytes > 5 * 1024 * 1024:
            raise InvalidInput("File is too large.", fields={"maxBytes": "invalid"})
        return SignedUpload(
            upload_url=f"https://storage.fake/upload/{path}",
            path=path,
            headers={"Content-Type": content_type},
        )

    async def signed_download(self, path: str) -> SignedDownload:
        if ".." in path:
            raise InvalidInput("That path is not allowed.", fields={"path": "invalid"})
        return SignedDownload(url=f"https://storage.fake/download/{path}")
