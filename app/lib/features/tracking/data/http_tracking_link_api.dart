import 'package:dio/dio.dart';

import '../../../core/api/generated/tracking/tracking_client.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/tracking_link_api.dart';

class HttpTrackingLinkApi implements TrackingLinkApi {
  HttpTrackingLinkApi({
    required TrackingClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final TrackingClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<TrackingLink>> create(String bookingId) async {
    try {
      final token = await _token();
      final body =
          await _client.createTrackingLinkV1BookingsBookingIdTrackingLinksPost(
        bookingId: bookingId,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(
        TrackingLink(token: body.token, path: body.path, expiresAt: body.expiresAt),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }
}
