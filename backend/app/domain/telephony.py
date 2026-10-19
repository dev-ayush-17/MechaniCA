from dataclasses import dataclass
from datetime import datetime

# Demo DID. Not a customer or mechanic mobile (FR-COM-002).
MASKED_DIAL_NUMBER = "+911140004444"


@dataclass(frozen=True)
class MaskedCall:
    dial_number: str
    expires_at: datetime
