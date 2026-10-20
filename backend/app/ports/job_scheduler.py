from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


@dataclass(frozen=True)
class ScheduledJob:
    id: str
    run_at: datetime
    target_path: str
    body: dict[str, str]


class JobScheduler(Protocol):
    async def schedule(self, job: ScheduledJob) -> None: ...

    async def cancel(self, job_id: str) -> None: ...
