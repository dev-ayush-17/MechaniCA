import pytest

from app.domain.booking_state import (
    BookingStatus,
    assert_transition,
    can_cancel,
    can_transition,
    cancel_fee_paise,
)
from app.domain.errors import InvalidTransition


def test_booking_state_rejects_cancel_after_arrived() -> None:
    assert can_cancel(BookingStatus.CONFIRMED)
    assert can_cancel(BookingStatus.EN_ROUTE)
    assert not can_cancel(BookingStatus.ARRIVED)
    assert not can_cancel(BookingStatus.IN_SERVICE)
    with pytest.raises(InvalidTransition, match="can't be cancelled"):
        cancel_fee_paise(BookingStatus.ARRIVED, enroute_fee_paise=9900)


def test_cancel_fee_zero_before_enroute() -> None:
    assert cancel_fee_paise(BookingStatus.REQUESTED, enroute_fee_paise=9900) == 0
    assert cancel_fee_paise(BookingStatus.CONFIRMED, enroute_fee_paise=9900) == 0
    assert cancel_fee_paise(BookingStatus.MECHANIC_ASSIGNED, enroute_fee_paise=9900) == 0
    assert cancel_fee_paise(BookingStatus.EN_ROUTE, enroute_fee_paise=9900) == 9900


def test_arrived_cannot_move_to_cancelled() -> None:
    assert not can_transition(BookingStatus.ARRIVED, BookingStatus.CANCELLED, "customer")
    with pytest.raises(InvalidTransition):
        assert_transition(BookingStatus.ARRIVED, BookingStatus.CANCELLED, "customer")


def test_mechanic_may_arrive_from_enroute() -> None:
    assert can_transition(BookingStatus.EN_ROUTE, BookingStatus.ARRIVED, "mechanic")
    assert not can_transition(BookingStatus.EN_ROUTE, BookingStatus.ARRIVED, "customer")
