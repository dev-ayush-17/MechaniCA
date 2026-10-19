from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import readiness_dep
from app.ports.readiness import ReadinessCheck

router = APIRouter()


@router.get("/health")
async def health() -> dict[str, str]:
    """Liveness. Touches nothing else."""
    return {"status": "ok"}


@router.get("/health/ready")
async def ready(
    readiness: Annotated[ReadinessCheck, Depends(readiness_dep)],
) -> dict[str, object]:
    """Readiness. 503 when any dependency is unhealthy."""
    checks = await readiness.check()
    if not all(checks.values()):
        raise HTTPException(status_code=503, detail={"status": "unavailable", "checks": checks})
    return {"status": "ok", "checks": checks}
