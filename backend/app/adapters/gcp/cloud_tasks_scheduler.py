"""Cloud Tasks JobScheduler. Bound only when MECHUPP_PROVIDER_SCHEDULER=cloud_tasks.

Dev and tests use FakeJobScheduler. This adapter is never constructed in those envs
and does not require a GCP project for the milestone (ADR-008).
"""

from datetime import UTC

from app.domain.errors import Unavailable
from app.ports.job_scheduler import ScheduledJob


class CloudTasksJobScheduler:
    def __init__(
        self,
        *,
        project_id: str,
        location: str,
        queue: str,
        handler_base_url: str,
        service_account_email: str,
    ) -> None:
        self._project_id = project_id
        self._location = location
        self._queue = queue
        self._handler_base_url = handler_base_url.rstrip("/")
        self._service_account_email = service_account_email

    async def schedule(self, job: ScheduledJob) -> None:
        try:
            from google.cloud import tasks_v2
        except ImportError as exc:
            raise Unavailable("Cloud Tasks client is not installed.") from exc
        client = tasks_v2.CloudTasksClient()
        parent = client.queue_path(self._project_id, self._location, self._queue)
        run_at = job.run_at if job.run_at.tzinfo else job.run_at.replace(tzinfo=UTC)
        from json import dumps

        body = dumps(job.body).encode()
        task = {
            "http_request": {
                "http_method": tasks_v2.HttpMethod.POST,
                "url": f"{self._handler_base_url}{job.target_path}",
                "headers": {"Content-Type": "application/json"},
                "body": body,
                "oidc_token": {"service_account_email": self._service_account_email},
            },
            "schedule_time": run_at,
            "name": client.task_path(
                self._project_id, self._location, self._queue, job.id.replace("-", "")
            ),
        }
        client.create_task(request={"parent": parent, "task": task})

    async def cancel(self, job_id: str) -> None:
        try:
            from google.cloud import tasks_v2
        except ImportError as exc:
            raise Unavailable("Cloud Tasks client is not installed.") from exc
        client = tasks_v2.CloudTasksClient()
        name = client.task_path(
            self._project_id, self._location, self._queue, job_id.replace("-", "")
        )
        client.delete_task(request={"name": name})
