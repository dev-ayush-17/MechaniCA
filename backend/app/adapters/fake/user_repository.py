from app.domain.user import User


class FakeUserRepository:
    """In-memory users collection. Process-local; a restart forgets everything."""

    def __init__(self) -> None:
        self._users: dict[str, User] = {}

    async def get(self, user_id: str) -> User | None:
        return self._users.get(user_id)

    async def upsert(self, user: User) -> User:
        self._users[user.id] = user
        return user
