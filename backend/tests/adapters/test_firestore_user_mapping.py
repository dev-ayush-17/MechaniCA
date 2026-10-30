from datetime import UTC, datetime

from app.adapters.firebase.user_repository import user_from_doc, user_to_doc
from app.domain.user import Role, User, UserStatus


def test_user_round_trip_mapping() -> None:
    now = datetime(2026, 10, 20, tzinfo=UTC)
    user = User(
        id="u1",
        role=Role.CUSTOMER,
        name="Ada",
        phone_e164="+919876543210",
        status=UserStatus.ACTIVE,
        auth_provider="fake",
        auth_subject="u1",
        created_at=now,
        updated_at=now,
    )
    doc = user_to_doc(user)
    back = user_from_doc("u1", doc)
    assert back == user
