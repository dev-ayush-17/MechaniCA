import 'package:dio/dio.dart';

import '../../../core/api/generated/mechanic/mechanic_client.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/earnings.dart';
import '../domain/earnings_api.dart';

class HttpEarningsApi implements EarningsApi {
  HttpEarningsApi({
    required MechanicClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final MechanicClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<EarningsList>> list() async {
    try {
      final token = await _token();
      final body = await _client.listMechanicEarningsV1MechanicEarningsGet(
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(
        EarningsList(
          notice: body.notice,
          items: [
            for (final item in body.items)
              MechanicEarning(
                bookingId: item.bookingId,
                displayNumber: item.displayNumber,
                sharePaise: item.sharePaise,
                totalPaise: item.totalPaise,
                paidAt: item.paidAt,
                payoutStatus: item.payoutStatus,
              ),
          ],
        ),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }
}
