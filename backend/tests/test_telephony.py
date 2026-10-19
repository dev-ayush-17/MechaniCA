from datetime import UTC, datetime

import pytest

from app.adapters.fake.clock import FakeClock
from app.adapters.fake.telephony import FakeTelephony
from app.domain.telephony import MASKED_DIAL_NUMBER


@pytest.mark.asyncio
async def test_adapter_does_not_return_the_user_phone() -> None:
    clock = FakeClock(datetime(2026, 6, 1, 10, 0, tzinfo=UTC))
    adapter = FakeTelephony(clock)
    customer_phone = "+919876543210"
    mechanic_phone = "+919811122233"
    call = await adapter.mask("book_1", customer_phone, mechanic_phone)
    assert call.dial_number == MASKED_DIAL_NUMBER
    assert call.dial_number != customer_phone
    assert call.dial_number != mechanic_phone
    payload = f"{call.dial_number}{call.expires_at.isoformat()}"
    assert "9876543210" not in payload
    assert "9811122233" not in payload
