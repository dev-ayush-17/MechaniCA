from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Response
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

from app.api.deps import manage_notifications_dep, principal_dep
from app.api.errors import error_responses
from app.application.manage_notifications import ManageNotifications
from app.domain.notification import InAppNotification
from app.domain.user import Principal

router = APIRouter(
    prefix="/v1/notifications",
    tags=["notifications"],
    responses=error_responses(400, 401, 403, 404),
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class NotificationOut(_Camel):
    id: str
    template_id: str
    title: str
    body: str
    deep_link: str
    read_at: datetime | None
    created_at: datetime

    @classmethod
    def of(cls, item: InAppNotification) -> "NotificationOut":
        return cls(
            id=item.id,
            template_id=item.template_id,
            title=item.title,
            body=item.body,
            deep_link=item.deep_link,
            read_at=item.read_at,
            created_at=item.created_at,
        )


class NotificationListOut(_Camel):
    items: list[NotificationOut]


@router.get("", response_model=NotificationListOut)
async def list_notifications(
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageNotifications, Depends(manage_notifications_dep)],
) -> NotificationListOut:
    items = await use_case.list_mine(principal)
    return NotificationListOut(items=[NotificationOut.of(item) for item in items])


@router.post("/{notification_id}/read", response_model=NotificationOut)
async def mark_read(
    notification_id: str,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageNotifications, Depends(manage_notifications_dep)],
) -> NotificationOut:
    item = await use_case.mark_read(principal, notification_id)
    return NotificationOut.of(item)


@router.delete("/{notification_id}", status_code=204)
async def delete_notification(
    notification_id: str,
    response: Response,
    principal: Annotated[Principal, Depends(principal_dep)],
    use_case: Annotated[ManageNotifications, Depends(manage_notifications_dep)],
) -> None:
    await use_case.delete(principal, notification_id)
    response.status_code = 204
