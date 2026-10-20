// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/edit_review_request.dart';
import '../models/review_list_out.dart';
import '../models/review_out.dart';
import '../models/submit_review_request.dart';

part 'reviews_client.g.dart';

@RestApi()
abstract class ReviewsClient {
  factory ReviewsClient(Dio dio, {String? baseUrl}) = _ReviewsClient;

  /// List Reviews
  @GET('/v1/reviews')
  Future<ReviewListOut> listReviewsV1ReviewsGet({
    @Query('mechanicId') required String mechanicId,
  });

  /// Submit Review
  @POST('/v1/reviews')
  Future<ReviewOut> submitReviewV1ReviewsPost({
    @Body() required SubmitReviewRequest body,
    @Header('authorization') String? authorization,
  });

  /// Edit Review
  @PATCH('/v1/reviews/{review_id}')
  Future<ReviewOut> editReviewV1ReviewsReviewIdPatch({
    @Path('review_id') required String reviewId,
    @Body() required EditReviewRequest body,
    @Header('authorization') String? authorization,
  });

  /// Hide Review
  @POST('/v1/reviews/{review_id}/hide')
  Future<ReviewOut> hideReviewV1ReviewsReviewIdHidePost({
    @Path('review_id') required String reviewId,
    @Header('authorization') String? authorization,
  });
}
