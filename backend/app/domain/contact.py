from dataclasses import dataclass


@dataclass(frozen=True)
class EmergencyContact:
    id: str
    owner_id: str
    name: str
    phone_e164: str
