import 'package:dio/dio.dart';

import '../../../core/api/generated/export.dart' as api;
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/review.dart';

class HttpReviewRepository implements ReviewRepository {
  HttpReviewRepository({required api.RestClient client}) : _client = client;

  final api.RestClient _client;

  @override
  Future<Result<MechanicReview>> submit({
    required String token,
    required String bookingId,
    required int stars,
    required String text,
  }) async {
    try {
      final out = await _client.reviews.submitReviewV1ReviewsPost(
        body: api.SubmitReviewRequest(
          bookingId: bookingId,
          stars: stars,
          text: text,
        ),
        authorization: 'Bearer $token',
      );
      return Ok(_toReview(out));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<MechanicReviewPage>> listForMechanic(String mechanicId) async {
    try {
      final out = await _client.reviews.listReviewsV1ReviewsGet(mechanicId: mechanicId);
      return Ok(
        MechanicReviewPage(
          items: out.items.map(_toReview).toList(),
          ratingAvg: out.ratingAvg.toDouble(),
          ratingCount: out.ratingCount,
        ),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  MechanicReview _toReview(api.ReviewOut out) => MechanicReview(
        id: out.id,
        bookingId: out.bookingId,
        mechanicId: out.mechanicId,
        stars: out.stars,
        text: out.text,
        status: out.status,
      );
}
