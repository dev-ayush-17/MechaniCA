from dataclasses import dataclass
from datetime import datetime, timedelta

TRACKING_LINK_TTL = timedelta(hours=6)


@dataclass(frozen=True)
class TrackingLink:
    token: str
    booking_id: str
    customer_id: str
    created_at: datetime
    expires_at: datetime
