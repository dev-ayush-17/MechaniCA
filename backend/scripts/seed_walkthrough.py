"""Seed two verified Patna mechanics and the service catalog on mechupp-staging.

Run from backend/ with the gitignored .env pointing at the Admin SDK credentials:

    .venv\\Scripts\\python scripts/seed_walkthrough.py

Sign-in (mechanic app, OTP 123456):

    +91 98000 00001  Ravi Kumar
    +91 98000 00002  Amit Singh

They are verified and offline. Go online in the mechanic app to receive offers.
Re-running this script takes them offline again.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime

from firebase_admin import firestore

from app.adapters.firebase.admin_app import ensure_firebase
from app.adapters.firebase.catalog_repository import FirestoreCatalogRepository
from app.adapters.firebase.mechanic_repository import mechanic_to_doc
from app.adapters.firebase.user_repository import FirestoreUserRepository
from app.core.config import get_settings
from app.domain.geo import geohash_encode
from app.domain.mechanic import Mechanic, ServiceArea, VerificationStatus
from app.domain.user import Role, User, UserStatus

PATNA_LAT = 25.5941
PATNA_LNG = 85.1376

MECHANICS = (
    ("+919800000001", "Ravi Kumar", 4.8, 12),
    ("+919800000002", "Amit Singh", 4.6, 8),
)


def _uid(phone: str) -> str:
    return "fake_" + phone.removeprefix("+")


async def seed() -> None:
    settings = get_settings()
    if not settings.firebase_project_id or not settings.firebase_credentials:
        raise SystemExit("Set MECHUPP_FIREBASE_PROJECT_ID and MECHUPP_FIREBASE_CREDENTIALS in .env")
    ensure_firebase(
        settings.firebase_project_id,
        credentials_path=settings.firebase_credentials,
        database_url=settings.firebase_database_url,
    )
    now = datetime.now(tz=UTC)
    users = FirestoreUserRepository(settings.firebase_project_id)
    catalog = FirestoreCatalogRepository(settings.firebase_project_id)
    services = await catalog.list_active_services()
    db = firestore.client()
    area = ServiceArea(
        lat=PATNA_LAT,
        lng=PATNA_LNG,
        radius_km=50.0,
        geohash=geohash_encode(PATNA_LAT, PATNA_LNG),
    )
    for phone, name, rating, count in MECHANICS:
        uid = _uid(phone)
        await users.upsert(
            User(
                id=uid,
                role=Role.MECHANIC,
                name=name,
                phone_e164=phone,
                status=UserStatus.ACTIVE,
                auth_provider="fake",
                auth_subject=uid,
                created_at=now,
                updated_at=now,
            )
        )
        mechanic = Mechanic(
            id=uid,
            display_name=name,
            photo_path="",
            years_experience=6,
            languages=("en", "hi"),
            service_area=area,
            verified=True,
            verification_status=VerificationStatus.APPROVED,
            online=False,
            last_heartbeat_at=None,
            rating_avg=rating,
            rating_count=count,
            version=1,
        )
        db.collection("mechanics").document(uid).set(mechanic_to_doc(mechanic))
        print(f"seeded {name} {phone} uid={uid}")  # noqa: T201
    print(f"catalog services: {', '.join(item.code for item in services)}")  # noqa: T201


if __name__ == "__main__":
    asyncio.run(seed())
