import 'package:dio/dio.dart';

import '../../../core/api/generated/coupons/coupons_client.dart';
import '../../../core/api/generated/models/coupon_out.dart';
import '../../../core/api/generated/models/validate_coupon_request.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/coupon_api.dart';
import '../domain/coupon_offer.dart';

class HttpCouponApi implements CouponApi {
  HttpCouponApi({
    required CouponsClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final CouponsClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<List<CouponOffer>>> list() async {
    try {
      final token = await _token();
      final body = await _client.listCouponsV1CouponsGet(
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok([for (final item in body.items) _map(item)]);
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<CouponQuote>> validate({
    required String code,
    required int laborPaise,
  }) async {
    try {
      final token = await _token();
      final body = await _client.validateCouponV1CouponsValidatePost(
        body: ValidateCouponRequest(code: code, laborPaise: laborPaise),
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(
        CouponQuote(
          code: body.code,
          discountPaise: body.discountPaise,
          message: body.message,
        ),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  CouponOffer _map(CouponOut item) => CouponOffer(
        code: item.code,
        title: item.title,
        description: item.description,
        type: item.type,
        amount: item.amount,
        maxDiscountPaise: item.maxDiscountPaise,
        minLaborPaise: item.minLaborPaise,
        endsAt: item.endsAt,
      );
}
