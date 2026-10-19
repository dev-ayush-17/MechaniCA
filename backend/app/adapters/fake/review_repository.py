from app.domain.review import RatingAggregate, Review, ReviewStatus, average_to_one_decimal


class FakeReviewRepository:
    def __init__(self) -> None:
        self.reviews: dict[str, Review] = {}

    async def save(self, review: Review) -> Review:
        self.reviews[review.id] = review
        return review

    async def get(self, review_id: str) -> Review | None:
        return self.reviews.get(review_id)

    async def get_by_booking(self, booking_id: str) -> Review | None:
        return next((item for item in self.reviews.values() if item.booking_id == booking_id), None)

    async def list_for_mechanic(self, mechanic_id: str) -> list[Review]:
        return [item for item in self.reviews.values() if item.mechanic_id == mechanic_id]

    async def recompute_aggregate(self, mechanic_id: str) -> RatingAggregate:
        published = [
            item
            for item in self.reviews.values()
            if item.mechanic_id == mechanic_id and item.status is ReviewStatus.PUBLISHED
        ]
        if not published:
            return RatingAggregate(rating_avg=0.0, rating_count=0)
        total = sum(item.stars for item in published)
        return RatingAggregate(
            rating_avg=average_to_one_decimal(total, len(published)),
            rating_count=len(published),
        )
