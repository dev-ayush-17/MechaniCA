from fastapi import FastAPI

from app.api import health
from app.api.errors import install_error_handling
from app.api.v1 import (
    admin_verification,
    bookings,
    catalog,
    me,
    mechanic,
    messages,
    notifications,
    offers,
    payments,
    quotes,
    reviews,
    vehicles,
)
from app.api.v1.internal import jobs as internal_jobs
from app.core.config import get_settings
from app.core.logging import configure_logging


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)
    app = FastAPI(title="MechUpp API", version="0.1.0")
    install_error_handling(app)
    app.include_router(health.router)
    app.include_router(me.router)
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
    app.include_router(reviews.proofs_router)
    app.include_router(reviews.reviews_router)
    app.include_router(payments.router)
    app.include_router(payments.wallet_router)
    app.include_router(payments.coupons_router)
    app.include_router(payments.admin_router)
    app.include_router(payments.earnings_router)
    app.include_router(payments.internal_router)
    return app


app = create_app()
