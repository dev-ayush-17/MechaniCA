"""Parts photo proof records. Paths are chosen by the server, never the client."""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from uuid import uuid4


class ProofKind(StrEnum):
    BEFORE = "before"
    AFTER = "after"
    OLD_PART = "old_part"


REQUIRED_PROOF_KINDS: frozenset[ProofKind] = frozenset(ProofKind)


def proof_storage_path(booking_id: str, line_id: str, kind: ProofKind) -> str:
    """FR-MEC-008: partsProof/{bookingId}/{lineId}/{kind}/{uuid}.jpg"""
    return f"partsProof/{booking_id}/{line_id}/{kind.value}/{uuid4()}.jpg"


@dataclass(frozen=True)
class PartsProof:
    id: str
    booking_id: str
    line_id: str
    kind: ProofKind
    storage_path: str
    captured_at: datetime
    hidden: bool
    metadata: dict[str, str]

    @classmethod
    def create(
        cls,
        *,
        booking_id: str,
        line_id: str,
        kind: ProofKind,
        storage_path: str,
        captured_at: datetime,
    ) -> "PartsProof":
        stamp = captured_at.isoformat().replace("+00:00", "Z")
        return cls(
            id=str(uuid4()),
            booking_id=booking_id,
            line_id=line_id,
            kind=kind,
            storage_path=storage_path,
            captured_at=captured_at,
            hidden=False,
            metadata={
                "bookingId": booking_id,
                "lineId": line_id,
                "kind": kind.value,
                "capturedAt": stamp,
            },
        )
