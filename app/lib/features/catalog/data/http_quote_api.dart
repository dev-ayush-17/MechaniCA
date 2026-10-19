import 'package:dio/dio.dart';

import '../../../core/api/generated/models/quote_request.dart';
import '../../../core/api/generated/quotes/quotes_client.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../../booking/domain/pricing.dart';
import '../../booking/domain/quote_api.dart';
import '../../vehicles/domain/vehicle.dart';

class HttpQuoteApi implements QuoteApi {
  HttpQuoteApi({
    required QuotesClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final QuotesClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<PriceQuote>> quote({
    required String serviceCode,
    required String vehicleId,
    required VehicleType vehicleType,
    String couponCode = '',
  }) async {
    try {
      final token = await _token();
      final body = await _client.createQuoteV1QuotesPost(
        body: QuoteRequest(
          vehicleId: vehicleId,
          serviceCode: serviceCode,
          couponCode: couponCode,
        ),
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(
        PriceQuote(
          laborPaise: body.laborPaise,
          partsPaise: body.partsPaise,
          feePaise: body.feePaise,
          discountPaise: body.discountPaise,
          cgstPaise: body.cgstPaise,
          sgstPaise: body.sgstPaise,
          totalPaise: body.totalPaise,
        ),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }
}
