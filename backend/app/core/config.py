from functools import lru_cache
from typing import Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

Env = Literal["dev", "test", "staging", "prod"]

# Fake auth and the demo OTP are allowed only here.
FAKE_AUTH_ENVS: frozenset[str] = frozenset({"dev", "test"})


class Settings(BaseSettings):
    """Process configuration. Provider choices come from here, never from business code."""

    model_config = SettingsConfigDict(env_file=".env", env_prefix="MECHANICA_", extra="ignore")

    app_env: Env = "dev"
    log_level: str = "INFO"
    # Which ReadinessCheck adapter deps.py binds. "fake" needs no network.
    provider_readiness: Literal["fake"] = "fake"
    # Which AuthVerifier and RoleClaims adapter deps.py binds.
    provider_auth: Literal["fake", "firebase"] = "fake"
    firebase_project_id: str | None = None

    @model_validator(mode="after")
    def _check_auth_provider(self) -> "Settings":
        if self.provider_auth == "fake" and self.app_env not in FAKE_AUTH_ENVS:
            raise ValueError("PROVIDER_AUTH=fake is not allowed outside dev and test")
        if self.provider_auth == "firebase" and not self.firebase_project_id:
            raise ValueError("MECHANICA_FIREBASE_PROJECT_ID is required for PROVIDER_AUTH=firebase")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
