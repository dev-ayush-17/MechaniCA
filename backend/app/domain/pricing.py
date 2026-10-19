"""Pure pricing. No I/O, no vendor imports, money in integer paise."""

from app.domain.catalog import BPS_DENOMINATOR, PriceQuote, PricingConfig, QuoteInput
from app.domain.errors import InvalidInput
from app.domain.vehicle import VehicleType


class PricingService:
    """Estimate from a loaded service, vehicle type, and config values."""

    def __init__(self, config: PricingConfig) -> None:
        self._config = config

    def quote(self, quote_input: QuoteInput) -> PriceQuote:
        if not quote_input.service.active:
            raise InvalidInput("This service is not available.")
        if quote_input.parts_paise < 0 or quote_input.discount_paise < 0:
            raise InvalidInput("Amounts cannot be negative.")
        if quote_input.service.base_labor_paise < 0:
            raise InvalidInput("Labor cannot be negative.")

        labor = quote_input.service.base_labor_paise
        if quote_input.vehicle_type is VehicleType.FOUR_WHEELER:
            labor = labor * self._config.four_wheeler_labor_bps // BPS_DENOMINATOR

        # Coupon discount is computed on labor (FR-PAY-001). Empty code means zero.
        discount = min(quote_input.discount_paise, labor)
        fee = self._config.convenience_fee_paise
        parts = quote_input.parts_paise
        # GST 18% on labor + convenience fee + parts (docs/prd/05).
        taxable = labor + fee + parts
        gst_total = taxable * self._config.gst_bps // BPS_DENOMINATOR
        cgst = gst_total // 2
        sgst = gst_total - cgst
        total = taxable - discount + gst_total
        return PriceQuote(
            labor_paise=labor,
            parts_paise=parts,
            fee_paise=fee,
            discount_paise=discount,
            cgst_paise=cgst,
            sgst_paise=sgst,
            total_paise=total,
        )
