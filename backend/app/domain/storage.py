from dataclasses import dataclass


@dataclass(frozen=True)
class SignedUpload:
    upload_url: str
    path: str
    headers: dict[str, str]


@dataclass(frozen=True)
class SignedDownload:
    url: str
