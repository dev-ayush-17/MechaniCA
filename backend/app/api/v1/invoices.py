from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import (
    get_invoice_dep,
    invoice_service_dep,
    principal_dep,
    require_internal_job_dep,
)
from app.api.errors import error_responses
from app.application.invoices import DefaultInvoiceService, GetInvoice
from app.domain.invoice import InvoiceFile
from app.domain.user import Principal

router = APIRouter(
    prefix="/v1/invoices",
    tags=["invoices"],
    responses=error_responses(401, 403, 404),
)
internal_router = APIRouter(
    prefix="/v1/internal/invoices",
    tags=["internal"],
    responses=error_responses(401, 404),
    dependencies=[Depends(require_internal_job_dep)],
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="forbid")


class InvoiceLineOut(_Camel):
    name: str
    quantity: int
    amount_paise: int


class InvoiceOut(_Camel):
    booking_id: str
    number: str
    version: int
    total_paise: int
    cgst_paise: int
    sgst_paise: int
    gstin: str
    customer_name: str
    vehicle_registration: str
    mechanic_display_name: str
    payment_method: str
    download_url: str
    created_at: datetime
    lines: list[InvoiceLineOut]

    @classmethod
    def of(cls, invoice: InvoiceFile, download_url: str) -> "InvoiceOut":
        return cls(
            booking_id=invoice.booking_id,
            number=invoice.number,
            version=invoice.version,
            total_paise=invoice.total_paise,
            cgst_paise=invoice.cgst_paise,
            sgst_paise=invoice.sgst_paise,
            gstin=invoice.gstin,
            customer_name=invoice.customer_name,
            vehicle_registration=invoice.vehicle_registration,
            mechanic_display_name=invoice.mechanic_display_name,
            payment_method=invoice.payment_method,
            download_url=download_url,
            created_at=invoice.created_at,
            lines=[
                InvoiceLineOut(
                    name=line.name, quantity=line.quantity, amount_paise=line.amount_paise
                )
                for line in invoice.lines
            ],
        )


class RenderInvoiceRequest(_Camel):
    booking_id: str


class InvoiceRenderOut(_Camel):
    ok: bool = True
    version: int
    number: str


@router.get("/{booking_id}", response_model=InvoiceOut)
async def get_invoice(
    booking_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[GetInvoice, Depends(get_invoice_dep)],
) -> InvoiceOut:
    invoice, url = await use_case.execute(principal, booking_id)
    return InvoiceOut.of(invoice, url)


@internal_router.post("/render", response_model=InvoiceRenderOut)
async def render_invoice(
    body: RenderInvoiceRequest,
    service: Annotated[DefaultInvoiceService, Depends(invoice_service_dep)],
) -> InvoiceRenderOut:
    invoice = await service.render(body.booking_id)
    return InvoiceRenderOut(version=invoice.version, number=invoice.number)
