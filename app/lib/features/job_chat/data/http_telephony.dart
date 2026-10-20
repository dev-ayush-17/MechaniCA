import 'package:dio/dio.dart';

import '../../../core/api/generated/messages/messages_client.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/telephony_port.dart';

class HttpTelephony implements TelephonyPort {
  HttpTelephony({
    required MessagesClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final MessagesClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<MaskedCall>> mask({
    required String bookingId,
    required String partyA,
    required String partyB,
  }) async {
    try {
      final token = await _token();
      final body = await _client.maskedCallV1BookingsBookingIdMaskedCallPost(
        bookingId: bookingId,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(
        MaskedCall(dialNumber: body.dialNumber, expiresAt: body.expiresAt),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }
}
