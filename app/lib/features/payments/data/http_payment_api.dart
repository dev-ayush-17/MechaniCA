import 'package:dio/dio.dart';

import '../../../core/api/generated/models/create_payment_request.dart';
import '../../../core/api/generated/models/payment_method.dart' as api;
import '../../../core/api/generated/models/payment_out.dart';
import '../../../core/api/generated/payments/payments_client.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../domain/payment.dart';
import '../domain/payment_api.dart';

class HttpPaymentApi implements PaymentApi {
  HttpPaymentApi({
    required PaymentsClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final PaymentsClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<Payment>> create({
    required String bookingId,
    required String method,
    required String idempotencyKey,
  }) async {
    try {
      final token = await _token();
      final body = await _client.createPaymentV1PaymentsPost(
        body: CreatePaymentRequest(
          bookingId: bookingId,
          method: api.PaymentMethod.fromJson(method),
        ),
        idempotencyKey: idempotencyKey,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(_map(body));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<Payment>> get(String paymentId) async {
    try {
      final token = await _token();
      final body = await _client.getPaymentV1PaymentsPaymentIdGet(
        paymentId: paymentId,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(_map(body));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  Payment _map(PaymentOut body) => Payment(
        id: body.paymentId,
        status: body.status,
        method: body.method,
        amountPaise: body.amountPaise,
        sessionId: body.cashfree?.paymentSessionId,
      );
}
