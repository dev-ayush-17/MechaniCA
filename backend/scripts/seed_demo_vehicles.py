"""Seed two vehicles with valid plates for a user (run against emulator or fake store).

Usage (from backend/, with env configured):
  python scripts/seed_demo_vehicles.py <userId>
"""

from __future__ import annotations

import asyncio
import sys
from datetime import UTC, datetime
from uuid import uuid4

from app.adapters.fake.vehicle_repository import FakeVehicleRepository
from app.domain.vehicle import Vehicle, VehicleType


async def seed(owner_id: str) -> None:
    repo = FakeVehicleRepository()
    now = datetime.now(tz=UTC)
    samples = [
        ("TVS", "Apache RTR 160 4V", "BR01AB1234", True),
        ("Yamaha", "MT-15", "BR02CD5678", False),
    ]
    for brand, model, plate, primary in samples:
        await repo.save(
            Vehicle(
                id=str(uuid4()),
                owner_id=owner_id,
                vehicle_type=VehicleType.TWO_WHEELER,
                brand=brand,
                model=model,
                year=2022,
                registration_number=plate,
                fuel_type="petrol",
                color="Black",
                odometer_km=5000,
                is_primary=primary,
                created_at=now,
                updated_at=now,
                version=1,
            )
        )
    sys.stdout.write(f"Seeded {len(samples)} vehicles for {owner_id}\n")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: python scripts/seed_demo_vehicles.py <userId>")
    asyncio.run(seed(sys.argv[1]))
