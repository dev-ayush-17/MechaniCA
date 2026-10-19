// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/cash_decision_request.dart';
import '../models/create_payment_request.dart';
import '../models/payment_out.dart';
import '../models/webhook_ack.dart';

part 'payments_client.g.dart';

@RestApi()
abstract class PaymentsClient {
  factory PaymentsClient(Dio dio, {String? baseUrl}) = _PaymentsClient;

  /// Create Payment
  @POST('/v1/payments')
  Future<PaymentOut> createPaymentV1PaymentsPost({
    @Body() required CreatePaymentRequest body,
    @Header('idempotency-key') String? idempotencyKey,
    @Header('authorization') String? authorization,
  });

  /// Cashfree Webhook
  @POST('/v1/payments/cashfree/webhook')
  Future<WebhookAck> cashfreeWebhookV1PaymentsCashfreeWebhookPost();

  /// Get Payment
  @GET('/v1/payments/{payment_id}')
  Future<PaymentOut> getPaymentV1PaymentsPaymentIdGet({
    @Path('payment_id') required String paymentId,
    @Header('authorization') String? authorization,
  });

  /// Cash Collected
  @POST('/v1/payments/{payment_id}/cash-collected')
  Future<PaymentOut> cashCollectedV1PaymentsPaymentIdCashCollectedPost({
    @Path('payment_id') required String paymentId,
    @Header('authorization') String? authorization,
  });

  /// Cash Confirm
  @POST('/v1/payments/{payment_id}/cash-confirm')
  Future<PaymentOut> cashConfirmV1PaymentsPaymentIdCashConfirmPost({
    @Path('payment_id') required String paymentId,
    @Body() required CashDecisionRequest body,
    @Header('authorization') String? authorization,
  });
}
