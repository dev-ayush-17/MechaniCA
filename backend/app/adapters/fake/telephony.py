from datetime import timedelta

from app.domain.telephony import MASKED_DIAL_NUMBER, MaskedCall
from app.ports.clock import Clock


class FakeTelephony:
    """Fixed test DID. Ignores party ids so a raw phone can never leak."""

    def __init__(self, clock: Clock) -> None:
        self._clock = clock

    async def mask(self, booking_id: str, party_a: str, party_b: str) -> MaskedCall:
        _ = (booking_id, party_a, party_b)
        return MaskedCall(
            dial_number=MASKED_DIAL_NUMBER,
            expires_at=self._clock.now() + timedelta(hours=1),
        )
