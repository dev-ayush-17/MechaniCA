from typing import Protocol

from app.domain.user import User


class UserRepository(Protocol):
    async def get(self, user_id: str) -> User | None: ...

    async def upsert(self, user: User) -> User: ...

    async def search(self, query: str) -> list[User]: ...
