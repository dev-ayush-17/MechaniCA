from app.domain.plate import is_valid_indian_plate, normalize_plate


def test_rejects_mock_plate_br80y024() -> None:
    assert not is_valid_indian_plate("BR80Y 024")


def test_accepts_br01ab1234() -> None:
    assert is_valid_indian_plate("BR01AB1234")
    assert normalize_plate("br01 ab 1234") == "BR01AB1234"
