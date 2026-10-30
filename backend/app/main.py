import asyncio
import logging
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import health
from app.api.errors import install_error_handling
from app.api.rate_limit import install_rate_limits
from app.api.v1 import (
    addresses,
    admin,
    admin_verification,
    bookings,
    catalog,
    invoices,
    me,
    mechanic,
    messages,
    notifications,
    offers,
    payments,
    quotes,
    reviews,
    tracking,
    vehicles,
)
from app.api.v1.internal import jobs as internal_jobs
from app.core.config import get_settings
from app.core.logging import configure_logging

_LOG = logging.getLogger("mechupp.jobs")


async def _run_dev_maintenance() -> None:
    from app.adapters.fake.job_scheduler import FakeJobScheduler
    from app.adapters.pdf import render_invoice_pdf
    from app.api import deps
    from app.application.invoices import DefaultInvoiceService

    settings = get_settings()
    dispatch = deps.dispatch_service_dep(
        deps.booking_repository_dep(),
        deps.offer_repository_dep(),
        deps.mechanic_repository_dep(),
        deps.notification_sender_dep(),
        deps.clock_dep(),
        deps.job_scheduler_dep(),
        deps.location_tracking_dep(),
        deps.analytics_service_dep(),
        deps.dispatch_config_dep(settings),
    )
    sweep = deps.sweep_expired_offers_dep(
        deps.offer_repository_dep(),
        deps.booking_repository_dep(),
        deps.mechanic_repository_dep(),
        dispatch,
        deps.clock_dep(),
        deps.expire_extra_line_dep(deps.booking_repository_dep(), deps.clock_dep()),
    )
    await sweep.execute()
    scheduler = deps._scheduler()
    if isinstance(scheduler, FakeJobScheduler):
        now = deps._clock().now()
        invoices = DefaultInvoiceService(
            invoices=deps._invoices(),
            storage=deps._storage(),
            bookings=deps.booking_repository_dep(),
            payments=deps._payments(),
            users=deps._users(),
            vehicles=deps._vehicles(),
            mechanics=deps._mechanics(),
            clock=deps._clock(),
            gstin=settings.gstin,
            render_pdf=render_invoice_pdf,
        )
        for job in scheduler.due(now):
            if str(job.target_path).endswith("/invoices/render"):
                booking_id = str(job.body.get("bookingId", ""))
                if booking_id:
                    try:
                        await invoices.render(booking_id)
                    except Exception as exc:
                        _LOG.warning(
                            "invoice_render_failed",
                            extra={
                                "fields": {
                                    "bookingId": booking_id,
                                    "error": type(exc).__name__,
                                }
                            },
                        )
            await scheduler.cancel(job.id)


async def _maintenance_loop(interval_seconds: int) -> None:
    while True:
        try:
            await _run_dev_maintenance()
        except Exception as exc:
            _LOG.warning("maintenance_failed", extra={"fields": {"error": type(exc).__name__}})
        await asyncio.sleep(interval_seconds)


@asynccontextmanager
async def _lifespan(_app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    task: asyncio.Task[None] | None = None
    if settings.dispatch_sweep_interval_seconds > 0 and not os.environ.get("PYTEST_CURRENT_TEST"):
        task = asyncio.create_task(_maintenance_loop(settings.dispatch_sweep_interval_seconds))
    try:
        yield
    finally:
        if task is not None:
            task.cancel()


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)
    app = FastAPI(title="MechUpp API", version="0.1.0", lifespan=_lifespan)
    install_rate_limits(app)
    install_error_handling(app)
    origins = settings.cors_origin_list()
    if origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=origins,
            allow_credentials=True,
            allow_methods=["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
            allow_headers=["Authorization", "Content-Type", "Idempotency-Key", "X-Request-Id"],
        )
    app.include_router(health.router)
    app.include_router(me.router)
    app.include_router(addresses.router)
    app.include_router(vehicles.router)
    app.include_router(catalog.router)
    app.include_router(quotes.router)
    app.include_router(bookings.router)
    app.include_router(offers.router)
    app.include_router(internal_jobs.router)
    app.include_router(notifications.router)
    app.include_router(messages.router)
    app.include_router(mechanic.router)
    app.include_router(mechanic.upload_router)
    app.include_router(admin_verification.router)
    app.include_router(admin.router)
    app.include_router(reviews.proofs_router)
    app.include_router(reviews.reviews_router)
    app.include_router(payments.router)
    app.include_router(payments.wallet_router)
    app.include_router(payments.coupons_router)
    app.include_router(payments.admin_router)
    app.include_router(payments.earnings_router)
    app.include_router(payments.internal_router)
    app.include_router(invoices.router)
    app.include_router(invoices.internal_router)
    app.include_router(tracking.links_router)
    app.include_router(tracking.public_router)
    return app


app = create_app()
