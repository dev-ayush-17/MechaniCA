from dataclasses import dataclass, replace
from datetime import timedelta
from uuid import uuid4

from app.domain.booking_state import BookingStatus
from app.domain.errors import Conflict, InvalidInput, NotFound, PermissionDenied
from app.domain.mechanic import Mechanic
from app.domain.review import RatingAggregate, Review, ReviewStatus, classify_review_text
from app.domain.user import Principal, Role
from app.ports.booking_repository import BookingRepository
from app.ports.clock import Clock
from app.ports.mechanic_repository import MechanicRepository
from app.ports.review_repository import ReviewRepository

_EDIT_WINDOW = timedelta(hours=48)
_MAX_TEXT = 500
_MAX_PHOTOS = 3


async def write_mechanic_aggregate(
    reviews: ReviewRepository, mechanics: MechanicRepository, mechanic_id: str
) -> RatingAggregate:
    aggregate = await reviews.recompute_aggregate(mechanic_id)
    mechanic = await mechanics.get(mechanic_id)
    if mechanic is None:
        return aggregate
    await mechanics.save_profile(
        Mechanic(
            id=mechanic.id,
            display_name=mechanic.display_name,
            photo_path=mechanic.photo_path,
            years_experience=mechanic.years_experience,
            languages=mechanic.languages,
            service_area=mechanic.service_area,
            verified=mechanic.verified,
            verification_status=mechanic.verification_status,
            online=mechanic.online,
            last_heartbeat_at=mechanic.last_heartbeat_at,
            rating_avg=aggregate.rating_avg,
            rating_count=aggregate.rating_count,
            version=mechanic.version,
            rejection_reason=mechanic.rejection_reason,
        )
    )
    return aggregate


def _validate_stars_and_text(stars: int, text: str) -> str:
    if stars < 1 or stars > 5:
        raise InvalidInput("Stars must be between 1 and 5.", fields={"stars": "invalid"})
    body = text.strip()
    if len(body) > _MAX_TEXT:
        raise InvalidInput("Keep the review under 500 characters.", fields={"text": "too_long"})
    return body


@dataclass(frozen=True)
class SubmitReview:
    bookings: BookingRepository
    reviews: ReviewRepository
    mechanics: MechanicRepository
    clock: Clock
    blocked_words: tuple[str, ...]

    async def execute(
        self,
        principal: Principal,
        *,
        booking_id: str,
        stars: int,
        text: str,
        photo_paths: tuple[str, ...] = (),
    ) -> Review:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        body = _validate_stars_and_text(stars, text)
        if len(photo_paths) > _MAX_PHOTOS:
            raise InvalidInput("Up to 3 photos.", fields={"photoPaths": "too_many"})
        booking = await self.bookings.get(booking_id)
        if booking is None:
            raise NotFound("We could not find that booking.")
        if booking.customer_id != principal.user_id:
            raise PermissionDenied("You do not have access to that booking.")
        if booking.status is not BookingStatus.PAID:
            raise InvalidInput("You can review after the job is paid.")
        if not booking.mechanic_id:
            raise InvalidInput("This booking has no mechanic to review.")
        if await self.reviews.get_by_booking(booking_id) is not None:
            raise Conflict("You already reviewed this booking.")
        now = self.clock.now()
        saved = await self.reviews.save(
            Review(
                id=str(uuid4()),
                booking_id=booking.id,
                customer_id=principal.user_id,
                mechanic_id=booking.mechanic_id,
                stars=stars,
                text=body,
                photo_paths=photo_paths,
                status=classify_review_text(body, self.blocked_words),
                created_at=now,
                updated_at=now,
                version=1,
            )
        )
        await write_mechanic_aggregate(self.reviews, self.mechanics, saved.mechanic_id)
        return saved


@dataclass(frozen=True)
class EditReview:
    reviews: ReviewRepository
    mechanics: MechanicRepository
    clock: Clock
    blocked_words: tuple[str, ...]

    async def execute(
        self,
        principal: Principal,
        review_id: str,
        *,
        stars: int,
        text: str,
    ) -> Review:
        if principal.role != Role.CUSTOMER:
            raise PermissionDenied("Customer account required.")
        existing = await self.reviews.get(review_id)
        if existing is None:
            raise NotFound("We could not find that review.")
        if existing.customer_id != principal.user_id:
            raise PermissionDenied("You do not have access to that review.")
        now = self.clock.now()
        if now - existing.created_at > _EDIT_WINDOW:
            raise Conflict("The edit window for this review has closed.")
        if existing.status is ReviewStatus.HIDDEN:
            raise Conflict("This review can no longer be edited.")
        body = _validate_stars_and_text(stars, text)
        saved = await self.reviews.save(
            replace(
                existing,
                stars=stars,
                text=body,
                status=classify_review_text(body, self.blocked_words),
                updated_at=now,
                version=existing.version + 1,
            )
        )
        await write_mechanic_aggregate(self.reviews, self.mechanics, saved.mechanic_id)
        return saved


@dataclass(frozen=True)
class ListReviews:
    reviews: ReviewRepository

    async def execute(self, mechanic_id: str) -> tuple[list[Review], RatingAggregate]:
        items = await self.reviews.list_for_mechanic(mechanic_id)
        visible = [item for item in items if item.status is ReviewStatus.PUBLISHED]
        return visible, await self.reviews.recompute_aggregate(mechanic_id)


@dataclass(frozen=True)
class HideReview:
    reviews: ReviewRepository
    mechanics: MechanicRepository

    async def execute(self, principal: Principal, review_id: str) -> Review:
        if principal.role not in {Role.ADMIN, Role.SUPER_ADMIN, Role.SUPPORT}:
            raise PermissionDenied("Staff access required.")
        review = await self.reviews.get(review_id)
        if review is None:
            raise NotFound("We could not find that review.")
        saved = await self.reviews.save(
            replace(review, status=ReviewStatus.HIDDEN, version=review.version + 1)
        )
        await write_mechanic_aggregate(self.reviews, self.mechanics, saved.mechanic_id)
        return saved
