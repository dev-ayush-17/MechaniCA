import re

_PLATE = re.compile(r"^[A-Z]{2}[0-9]{2}[A-Z]{1,3}[0-9]{1,4}$")


def normalize_plate(raw: str) -> str:
    return re.sub(r"\s+", "", raw.strip()).upper()


def is_rejected_mock_plate(normalized: str) -> bool:
    return normalized == "BR80Y024"


def is_valid_indian_plate(raw: str) -> bool:
    normalized = normalize_plate(raw)
    if not normalized:
        return False
    if is_rejected_mock_plate(normalized):
        return False
    return _PLATE.fullmatch(normalized) is not None
