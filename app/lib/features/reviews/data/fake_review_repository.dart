import '../../../core/error/result.dart';
import '../domain/review.dart';

class FakeReviewRepository implements ReviewRepository {
  final List<MechanicReview> stored = [];

  @override
  Future<Result<MechanicReview>> submit({
    required String token,
    required String bookingId,
    required int stars,
    required String text,
  }) async {
    if (stored.any((item) => item.bookingId == bookingId)) {
      return const Err(Conflict('You already reviewed this booking.', code: 'conflict'));
    }
    final review = MechanicReview(
      id: 'rev_${stored.length + 1}',
      bookingId: bookingId,
      mechanicId: 'mech_1',
      stars: stars,
      text: text,
      status: text.trim().isEmpty ? 'published' : 'published',
    );
    stored.add(review);
    return Ok(review);
  }

  @override
  Future<Result<MechanicReviewPage>> listForMechanic(String mechanicId) async {
    final items = stored
        .where((item) => item.mechanicId == mechanicId && item.status == 'published')
        .toList();
    if (items.isEmpty) {
      return const Ok(MechanicReviewPage(items: [], ratingAvg: 0, ratingCount: 0));
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.stars);
    return Ok(
      MechanicReviewPage(
        items: items,
        ratingAvg: double.parse((total / items.length).toStringAsFixed(1)),
        ratingCount: items.length,
      ),
    );
  }
}
