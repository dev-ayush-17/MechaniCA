class FakeReadiness:
    def __init__(self, checks: dict[str, bool] | None = None) -> None:
        self._checks = checks if checks is not None else {"fake": True}

    async def check(self) -> dict[str, bool]:
        return dict(self._checks)
