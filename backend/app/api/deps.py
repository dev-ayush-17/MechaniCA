"""Composition root: the only place that decides which adapter implements a port."""

from functools import lru_cache

from app.adapters.fake.readiness import FakeReadiness
from app.adapters.system_clock import SystemClock
from app.core.config import Settings, get_settings
from app.ports.clock import Clock
from app.ports.readiness import ReadinessCheck


def settings_dep() -> Settings:
    return get_settings()


@lru_cache
def _clock() -> Clock:
    return SystemClock()


def clock_dep() -> Clock:
    return _clock()


@lru_cache
def _readiness() -> ReadinessCheck:
    # M02+ adds Firestore and task-queue adapters selected by Settings.provider_readiness.
    return FakeReadiness()


def readiness_dep() -> ReadinessCheck:
    return _readiness()
