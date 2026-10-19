"""Catalog and quote value objects. Money fields are integer paise."""

from dataclasses import dataclass

from app.domain.vehicle import VehicleType

# 15000 bps = 1.5x. Stored as integers so labor never uses a binary float.
FOUR_WHEELER_LABOR_BPS = 15_000
GST_BPS = 1_800
CONVENIENCE_FEE_PAISE = 4_900
BPS_DENOMINATOR = 10_000


@dataclass(frozen=True)
class ServiceDefinition:
    code: str
    name: str
    description: str
    base_labor_paise: int
    duration_min: int
    active: bool
    sort_order: int


@dataclass(frozen=True)
class PricingConfig:
    convenience_fee_paise: int
    four_wheeler_labor_bps: int
    gst_bps: int


DEFAULT_PRICING_CONFIG = PricingConfig(
    convenience_fee_paise=CONVENIENCE_FEE_PAISE,
    four_wheeler_labor_bps=FOUR_WHEELER_LABOR_BPS,
    gst_bps=GST_BPS,
)


@dataclass(frozen=True)
class QuoteInput:
    service: ServiceDefinition
    vehicle_type: VehicleType
    parts_paise: int = 0
    discount_paise: int = 0


@dataclass(frozen=True)
class PriceQuote:
    labor_paise: int
    parts_paise: int
    fee_paise: int
    discount_paise: int
    cgst_paise: int
    sgst_paise: int
    total_paise: int
