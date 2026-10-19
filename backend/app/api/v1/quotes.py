from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import create_quote_dep, principal_dep
from app.api.errors import error_responses
from app.application.create_quote import CreateQuote
from app.domain.catalog import PriceQuote
from app.domain.user import Principal

router = APIRouter(
    prefix="/v1/quotes", tags=["quotes"], responses=error_responses(400, 401, 403, 404)
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class QuoteRequest(_Camel):
    vehicle_id: str
    service_code: str
    coupon_code: str = ""


class QuoteOut(_Camel):
    labor_paise: int
    parts_paise: int
    fee_paise: int
    discount_paise: int
    cgst_paise: int
    sgst_paise: int
    total_paise: int

    @classmethod
    def of(cls, quote: PriceQuote) -> "QuoteOut":
        return cls(
            labor_paise=quote.labor_paise,
            parts_paise=quote.parts_paise,
            fee_paise=quote.fee_paise,
            discount_paise=quote.discount_paise,
            cgst_paise=quote.cgst_paise,
            sgst_paise=quote.sgst_paise,
            total_paise=quote.total_paise,
        )


@router.post("", response_model=QuoteOut)
async def create_quote(
    body: QuoteRequest,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[CreateQuote, Depends(create_quote_dep)],
) -> QuoteOut:
    quote = await use_case.execute(
        principal,
        service_code=body.service_code,
        vehicle_id=body.vehicle_id,
        coupon_code=body.coupon_code,
    )
    return QuoteOut.of(quote)
