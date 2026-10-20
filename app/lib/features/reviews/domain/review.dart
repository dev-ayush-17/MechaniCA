import '../../../core/error/result.dart';

class MechanicReview {
  const MechanicReview({
    required this.id,
    required this.bookingId,
    required this.mechanicId,
    required this.stars,
    required this.text,
    required this.status,
  });

  final String id;
  final String bookingId;
  final String mechanicId;
  final int stars;
  final String text;
  final String status;
}

class MechanicReviewPage {
  const MechanicReviewPage({
    required this.items,
    required this.ratingAvg,
    required this.ratingCount,
  });

  final List<MechanicReview> items;
  final double ratingAvg;
  final int ratingCount;

  String get ratingLabel => ratingAvg.toStringAsFixed(1);
}

abstract interface class ReviewRepository {
  Future<Result<MechanicReview>> submit({
    required String token,
    required String bookingId,
    required int stars,
    required String text,
  });

  Future<Result<MechanicReviewPage>> listForMechanic(String mechanicId);
}
