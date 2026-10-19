// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/payment_out.dart';
import '../models/topup_request.dart';
import '../models/wallet_out.dart';

part 'wallet_client.g.dart';

@RestApi()
abstract class WalletClient {
  factory WalletClient(Dio dio, {String? baseUrl}) = _WalletClient;

  /// Get Wallet
  @GET('/v1/wallet')
  Future<WalletOut> getWalletV1WalletGet({
    @Header('authorization') String? authorization,
  });

  /// Create Topup
  @POST('/v1/wallet/topups')
  Future<PaymentOut> createTopupV1WalletTopupsPost({
    @Body() required TopupRequest body,
    @Header('idempotency-key') String? idempotencyKey,
    @Header('authorization') String? authorization,
  });
}
