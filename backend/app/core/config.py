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
    provider_payments: Literal["fake", "cashfree"] = "fake"
    payments_webhook_secret: str = "mechupp_test_webhook_secret"  # noqa: S105 - fake gateway default
    cashfree_app_id: str | None = None
    cashfree_secret: str | None = None
    cashfree_api_url: str = "https://sandbox.cashfree.com/pg"
    mechanic_labor_share_bps: int = 8000
    provider_notifications: Literal["fake", "firestore"] = "fake"
    provider_notify: Literal["fake", "fcm"] = "fake"
    sms_enabled: bool = False
    provider_scheduler: Literal["fake", "cloud_tasks"] = "fake"
    provider_chat: Literal["fake", "firestore"] = "fake"
    provider_telephony: Literal["fake", "unavailable"] = "fake"
    provider_maps: Literal["fake", "google"] = "fake"
    maps_api_key: str | None = None
    provider_location: Literal["fake", "rtdb"] = "fake"
    firebase_database_url: str | None = None
    # None means on in dev/test/staging and off in prod (FR-COM-002).
    masked_call_enabled: bool | None = None
    firebase_project_id: str | None = None
    internal_job_token: str = "dev-internal-job"  # noqa: S105 - local stand-in for OIDC
    cloud_tasks_location: str = "asia-south1"
    cloud_tasks_queue: str = "mechupp-jobs"
    cloud_tasks_handler_base_url: str = "http://localhost:8080"
    cloud_tasks_service_account: str | None = None
    convenience_fee_paise: int = 4900
    four_wheeler_labor_bps: int = 15000
    gst_bps: int = 1800
    booking_auto_confirm: bool = True
    cancel_fee_enroute_paise: int = 9900
    service_area_lat: float = 25.5941
    service_area_lng: float = 85.1376
    service_area_radius_km: float = 50.0
    review_blocked_words: str = "spam,scam"

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
        if self.provider_payments == "fake" and self.app_env not in FAKE_AUTH_ENVS:
            raise ValueError("PROVIDER_PAYMENTS=fake is not allowed outside dev and test")
        if self.provider_payments == "cashfree" and (
            not self.cashfree_app_id or not self.cashfree_secret
        ):
            raise ValueError(
                "Cashfree app id and secret are required for PROVIDER_PAYMENTS=cashfree"
            )
        if self.provider_notifications == "firestore" and not self.firebase_project_id:
            raise ValueError(
                "MECHUPP_FIREBASE_PROJECT_ID is required for PROVIDER_NOTIFICATIONS=firestore"
            )
        if self.provider_notify == "fcm" and not self.firebase_project_id:
            raise ValueError("MECHUPP_FIREBASE_PROJECT_ID is required for PROVIDER_NOTIFY=fcm")
        if self.provider_chat == "firestore" and not self.firebase_project_id:
            raise ValueError("MECHUPP_FIREBASE_PROJECT_ID is required for PROVIDER_CHAT=firestore")
        if self.provider_location == "rtdb" and (
            not self.firebase_project_id or not self.firebase_database_url
        ):
            raise ValueError(
                "MECHUPP_FIREBASE_PROJECT_ID and MECHUPP_FIREBASE_DATABASE_URL "
                "are required for PROVIDER_LOCATION=rtdb"
            )
        return self

    def is_masked_call_enabled(self) -> bool:
        if self.masked_call_enabled is None:
            return self.app_env != "prod"
        return self.masked_call_enabled


@lru_cache
def get_settings() -> Settings:
    return Settings()
