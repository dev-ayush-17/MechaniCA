from typing import Protocol

from app.domain.telephony import MaskedCall


class TelephonyPort(Protocol):
    """Returns a bridge number. Never the other party's real phone."""

    async def mask(self, booking_id: str, party_a: str, party_b: str) -> MaskedCall: ...
