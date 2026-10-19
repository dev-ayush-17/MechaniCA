// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/coupon_list_out.dart';
import '../models/coupon_quote_out.dart';
import '../models/validate_coupon_request.dart';

part 'coupons_client.g.dart';

@RestApi()
abstract class CouponsClient {
  factory CouponsClient(Dio dio, {String? baseUrl}) = _CouponsClient;

  /// List Coupons
  @GET('/v1/coupons')
  Future<CouponListOut> listCouponsV1CouponsGet({
    @Header('authorization') String? authorization,
  });

  /// Validate Coupon
  @POST('/v1/coupons/validate')
  Future<CouponQuoteOut> validateCouponV1CouponsValidatePost({
    @Body() required ValidateCouponRequest body,
    @Header('authorization') String? authorization,
  });
}
