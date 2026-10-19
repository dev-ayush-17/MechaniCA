from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Process configuration. Provider choices come from here, never from business code."""

    model_config = SettingsConfigDict(env_file=".env", env_prefix="MECHANICA_", extra="ignore")

    app_env: Literal["dev", "staging", "prod"] = "dev"
    log_level: str = "INFO"
    # Which ReadinessCheck adapter deps.py binds. "fake" needs no network.
    provider_readiness: Literal["fake"] = "fake"


@lru_cache
def get_settings() -> Settings:
    return Settings()
