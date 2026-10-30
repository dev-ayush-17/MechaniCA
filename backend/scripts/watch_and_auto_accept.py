"""Background auto-acceptance daemon for staging bookings and offers.

Ensures any booking created on staging (via Cloud Run or local server)
is automatically matched and accepted by the server without manual
interaction on the mechanic phone.

Run:
    .venv\\Scripts\\python scripts/watch_and_auto_accept.py
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime
import logging
import sys
import warnings

from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

from app.adapters.firebase.admin_app import ensure_firebase
from app.api import deps
from app.core.config import get_settings
from app.domain.booking_state import BookingStatus
from app.domain.dispatch import OfferStatus

warnings.filterwarnings("ignore", category=UserWarning)
_LOG = logging.getLogger("mechupp.auto_accept")
AMIT_SINGH_UID = "rLbLmYXRgaVV9X7KIQvZQR0hXQ62"


def _log(msg: str) -> None:
    print(msg, flush=True)  # noqa: T201


async def main() -> None:
    settings = get_settings()
    if not settings.firebase_project_id or not settings.firebase_credentials:
        raise SystemExit("Missing Firebase configuration in .env")

    ensure_firebase(
        settings.firebase_project_id,
        credentials_path=settings.firebase_credentials,
        database_url=settings.firebase_database_url,
    )
    db = firestore.client()

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

    _log("=" * 60)
    _log(f"Auto-accept daemon started for project: {settings.firebase_project_id}")
    _log(f"Fallback mechanic UID: {AMIT_SINGH_UID} (Amit Singh)")
    _log("Watching for confirmed bookings and open offers in real time...")
    _log("=" * 60)

    last_heartbeat = datetime.min.replace(tzinfo=UTC)

    while True:
        try:
            now = datetime.now(tz=UTC)

            # 1. Keep Amit Singh online and fresh heartbeat every 15s
            if (now - last_heartbeat).total_seconds() > 15:
                try:
                    await deps.mechanic_repository_dep().record_heartbeat(AMIT_SINGH_UID, at=now)
                    await deps.mechanic_repository_dep().set_availability(AMIT_SINGH_UID, online=True)
                    last_heartbeat = now
                except Exception as exc:
                    _LOG.warning("Heartbeat refresh failed: %s", exc)

            # 2. Check for open offers
            open_offers = db.collection("offers").where(filter=FieldFilter("status", "==", OfferStatus.OPEN.value)).stream()
            for snap in open_offers:
                data = snap.to_dict() or {}
                offer_id = snap.id
                mechanic_id = str(data.get("mechanicId") or AMIT_SINGH_UID)
                booking_id = str(data.get("bookingId") or "")
                _log(f"[AUTO-ACCEPT] Found open offer {offer_id} for booking {booking_id}. Accepting for {mechanic_id}...")
                try:
                    booking = await dispatch.accept(offer_id, mechanic_id)
                    _log(f"[AUTO-ACCEPT] Successfully accepted offer {offer_id}! Booking {booking.id} is now {booking.status.value}")
                except Exception as exc:
                    _log(f"[AUTO-ACCEPT] Error accepting offer {offer_id}: {exc}")

            # 3. Check for confirmed bookings that need dispatch
            confirmed_snaps = db.collection("bookings").where(filter=FieldFilter("status", "==", BookingStatus.CONFIRMED.value)).stream()
            for snap in confirmed_snaps:
                booking_id = snap.id
                _log(f"[AUTO-ACCEPT] Found confirmed booking {booking_id}. Dispatching offer...")
                try:
                    offer = await dispatch.offer(booking_id)
                    if offer is not None:
                        _log(f"[AUTO-ACCEPT] Dispatched and processed offer {offer.id} for booking {booking_id}")
                    else:
                        _log(f"[AUTO-ACCEPT] Booking {booking_id} dispatch returned None (already processed or waiting)")
                except Exception as exc:
                    _log(f"[AUTO-ACCEPT] Error dispatching booking {booking_id}: {exc}")

        except Exception as loop_err:
            _log(f"[AUTO-ACCEPT] Error in poll loop: {loop_err}")

        await asyncio.sleep(1.0)


if __name__ == "__main__":
    asyncio.run(main())
