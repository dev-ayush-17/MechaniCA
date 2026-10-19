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

# Seed catalog from docs/prd/05-functional-requirements.md (FR-BOOK-003).
SEED_SERVICES: tuple[ServiceDefinition, ...] = (
    ServiceDefinition(
        code="general_service",
        name="General Service",
        description="Periodic inspection, fluids, and adjustments",
        base_labor_paise=59900,
        duration_min=60,
        active=True,
        sort_order=1,
    ),
    ServiceDefinition(
        code="oil_change",
        name="Oil Change",
        description="Engine oil and filter replacement",
        base_labor_paise=39900,
        duration_min=45,
        active=True,
        sort_order=2,
    ),
    ServiceDefinition(
        code="engine_issue",
        name="Engine Issue",
        description="Diagnosis and repair of running problems",
        base_labor_paise=49900,
        duration_min=90,
        active=True,
        sort_order=3,
    ),
    ServiceDefinition(
        code="brake_repair",
        name="Brake Repair",
        description="Brake pad, disc, and fluid work",
        base_labor_paise=34900,
        duration_min=45,
        active=True,
        sort_order=4,
    ),
    ServiceDefinition(
        code="breakdown",
        name="Breakdown assist",
        description="Roadside help when the vehicle will not run",
        base_labor_paise=49900,
        duration_min=60,
        active=True,
        sort_order=5,
    ),
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
