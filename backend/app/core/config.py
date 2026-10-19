from functools import lru_cache
from typing import Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

Env = Literal["dev", "test", "staging", "prod"]

# Fake auth and the demo OTP are allowed only here.
FAKE_AUTH_ENVS: frozenset[str] = frozenset({"dev", "test"})


class Settings(BaseSettings):
    """Process configuration. Provider choices come from here, never from business code."""

    model_config = SettingsConfigDict(env_file=".env", env_prefix="MECHUPP_", extra="ignore")

    app_env: Env = "dev"
    log_level: str = "INFO"
    # Which ReadinessCheck adapter deps.py binds. "fake" needs no network.
    provider_readiness: Literal["fake"] = "fake"
    # Which AuthVerifier and RoleClaims adapter deps.py binds.
    provider_auth: Literal["fake", "firebase"] = "fake"
    provider_vehicles: Literal["fake", "firestore"] = "fake"
    provider_catalog: Literal["fake", "firestore"] = "fake"
    provider_bookings: Literal["fake", "firestore"] = "fake"
    provider_chat: Literal["fake", "firestore"] = "fake"
    firebase_project_id: str | None = None
    convenience_fee_paise: int = 4900
    four_wheeler_labor_bps: int = 15000
    gst_bps: int = 1800
    booking_auto_confirm: bool = True
    cancel_fee_enroute_paise: int = 9900
    service_area_lat: float = 25.5941
    service_area_lng: float = 85.1376
    service_area_radius_km: float = 50.0

    @model_validator(mode="after")
    def _check_auth_provider(self) -> "Settings":
        if self.provider_auth == "fake" and self.app_env not in FAKE_AUTH_ENVS:
            raise ValueError("PROVIDER_AUTH=fake is not allowed outside dev and test")
        if self.provider_auth == "firebase" and not self.firebase_project_id:
            raise ValueError("MECHUPP_FIREBASE_PROJECT_ID is required for PROVIDER_AUTH=firebase")
        if self.provider_vehicles == "firestore" and not self.firebase_project_id:
            raise ValueError(
                "MECHUPP_FIREBASE_PROJECT_ID is required for PROVIDER_VEHICLES=firestore"
            )
        if self.provider_catalog == "firestore" and not self.firebase_project_id:
            raise ValueError(
                "MECHUPP_FIREBASE_PROJECT_ID is required for PROVIDER_CATALOG=firestore"
            )
        if self.provider_bookings == "firestore" and not self.firebase_project_id:
            raise ValueError(
                "MECHUPP_FIREBASE_PROJECT_ID is required for PROVIDER_BOOKINGS=firestore"
            )
        if self.provider_chat == "firestore" and not self.firebase_project_id:
            raise ValueError("MECHUPP_FIREBASE_PROJECT_ID is required for PROVIDER_CHAT=firestore")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
