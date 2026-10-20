import re
from dataclasses import dataclass, replace

from app.domain.errors import InvalidInput, NotFound
from app.domain.user import Principal, User
from app.ports.clock import Clock
from app.ports.user_repository import UserRepository

_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


@dataclass(frozen=True)
class UpdateProfile:
    users: UserRepository
    clock: Clock

    async def execute(
        self, principal: Principal, *, name: str | None, email: str | None
    ) -> User:
        user = await self.users.get(principal.user_id)
        if user is None:
            raise NotFound("Finish sign-in first.")
        next_name = user.name if name is None else name.strip()
        if len(next_name) < 2 or len(next_name) > 60:
            raise InvalidInput("Name must be 2 to 60 characters.")
        next_email = user.email if email is None else email.strip()
        if next_email == "":
            next_email = None
        if next_email is not None and _EMAIL.fullmatch(next_email) is None:
            raise InvalidInput("Enter a valid email address.")
        saved = replace(user, name=next_name, email=next_email, updated_at=self.clock.now())
        return await self.users.upsert(saved)
