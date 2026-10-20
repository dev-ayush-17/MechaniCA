from app.domain.errors import Unavailable
from app.domain.telephony import MaskedCall


class UnavailableTelephony:
    """Real-adapter stand-in until a vendor is contracted (FR-COM-002)."""

    async def mask(self, booking_id: str, party_a: str, party_b: str) -> MaskedCall:
        _ = (booking_id, party_a, party_b)
        raise Unavailable("Calling is unavailable. Use chat.")
