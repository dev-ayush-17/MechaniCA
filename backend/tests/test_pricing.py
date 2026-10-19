from app.domain.catalog import DEFAULT_PRICING_CONFIG, QuoteInput, ServiceDefinition
from app.domain.errors import InvalidInput
from app.domain.pricing import PricingService
from app.domain.vehicle import VehicleType

GENERAL = ServiceDefinition(
    code="general_service",
    name="General Service",
    description="Full service",
    base_labor_paise=59900,
    duration_min=60,
    active=True,
    sort_order=1,
)


def test_gst_on_59900_plus_4900_splits() -> None:
    quote = PricingService(DEFAULT_PRICING_CONFIG).quote(
        QuoteInput(service=GENERAL, vehicle_type=VehicleType.TWO_WHEELER)
    )
    assert quote.labor_paise == 59900
    assert quote.fee_paise == 4900
    assert quote.parts_paise == 0
    assert quote.discount_paise == 0
    assert quote.cgst_paise == 5832
    assert quote.sgst_paise == 5832
    assert quote.cgst_paise + quote.sgst_paise == 11664
    assert abs(quote.cgst_paise - quote.sgst_paise) <= 1
    assert quote.total_paise == 76464


def test_four_wheeler_labor_is_one_and_a_half() -> None:
    quote = PricingService(DEFAULT_PRICING_CONFIG).quote(
        QuoteInput(service=GENERAL, vehicle_type=VehicleType.FOUR_WHEELER)
    )
    assert quote.labor_paise == 89850
    taxable = 89850 + 4900
    gst = taxable * 18 // 100
    assert quote.cgst_paise + quote.sgst_paise == gst
    assert abs(quote.cgst_paise - quote.sgst_paise) <= 1
    assert quote.total_paise == taxable + gst


def test_inactive_service_is_rejected() -> None:
    inactive = ServiceDefinition(
        code="oil_change",
        name="Oil Change",
        description="",
        base_labor_paise=39900,
        duration_min=45,
        active=False,
        sort_order=2,
    )
    try:
        PricingService(DEFAULT_PRICING_CONFIG).quote(
            QuoteInput(service=inactive, vehicle_type=VehicleType.TWO_WHEELER)
        )
    except InvalidInput as exc:
        assert exc.code == "invalid_input"
        assert "not available" in exc.message.lower()
    else:
        raise AssertionError("inactive service must raise InvalidInput")
