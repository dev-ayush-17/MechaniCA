from fastapi import FastAPI

from app.api import health
from app.api.errors import install_error_handling
from app.api.v1 import me
from app.core.config import get_settings
from app.core.logging import configure_logging


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)
    app = FastAPI(title="MechUpp API", version="0.1.0")
    install_error_handling(app)
    app.include_router(health.router)
    app.include_router(me.router)
    return app


app = create_app()
