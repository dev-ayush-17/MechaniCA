from datetime import datetime

from app.ports.job_scheduler import ScheduledJob


class FakeJobScheduler:
    """In-memory scheduler. Tests call run_due. Dev never enqueues Cloud Tasks."""

    def __init__(self) -> None:
        self.jobs: dict[str, ScheduledJob] = {}

    async def schedule(self, job: ScheduledJob) -> None:
        self.jobs[job.id] = job

    async def cancel(self, job_id: str) -> None:
        self.jobs.pop(job_id, None)

    def due(self, now: datetime) -> list[ScheduledJob]:
        return [job for job in self.jobs.values() if job.run_at <= now]
