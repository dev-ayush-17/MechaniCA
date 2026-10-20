import 'package:dio/dio.dart';

import '../../../core/api/generated/bookings/bookings_client.dart';
import '../../../core/api/generated/models/booking_status.dart' as api;
import '../../../core/api/generated/models/transition_request.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/job_transition_api.dart';

class HttpJobTransitionApi implements JobTransitionApi {
  HttpJobTransitionApi({
    required BookingsClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final BookingsClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<String>> transition(String bookingId, String to) async {
    try {
      final token = await _token();
      final body =
          await _client.transitionBookingV1BookingsBookingIdTransitionsPost(
        bookingId: bookingId,
        body: TransitionRequest(to: api.BookingStatus.fromJson(to)),
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(body.status);
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }
}
