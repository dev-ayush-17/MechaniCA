import 'package:dio/dio.dart';

import '../../../core/api/generated/models/payment_out.dart';
import '../../../core/api/generated/models/topup_request.dart';
import '../../../core/api/generated/wallet/wallet_client.dart';
import '../../../core/error/result.dart';
import '../../auth/data/http_account_api.dart';
import '../../payments/domain/payment.dart';
import '../domain/wallet_api.dart';
import '../domain/wallet_snapshot.dart';

class HttpWalletApi implements WalletApi {
  HttpWalletApi({
    required WalletClient client,
    required Future<String?> Function() token,
  })  : _client = client,
        _token = token;

  final WalletClient _client;
  final Future<String?> Function() _token;

  @override
  Future<Result<WalletSnapshot>> getWallet() async {
    try {
      final token = await _token();
      final body = await _client.getWalletV1WalletGet(
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(
        WalletSnapshot(
          balancePaise: body.balancePaise,
          items: [
            for (final item in body.items)
              WalletLedgerItem(
                id: item.id,
                reason: item.reason,
                amountPaise: item.amountPaise,
                direction: item.direction,
                createdAt: item.createdAt,
              ),
          ],
        ),
      );
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  @override
  Future<Result<Payment>> topup({
    required int amountPaise,
    required String idempotencyKey,
  }) async {
    try {
      final token = await _token();
      final body = await _client.createTopupV1WalletTopupsPost(
        body: TopupRequest(amountPaise: amountPaise),
        idempotencyKey: idempotencyKey,
        authorization: token == null ? null : 'Bearer $token',
      );
      return Ok(_mapPayment(body));
    } on DioException catch (e) {
      return Err(failureFromDio(e));
    }
  }

  Payment _mapPayment(PaymentOut body) => Payment(
        id: body.paymentId,
        status: body.status,
        method: body.method,
        amountPaise: body.amountPaise,
        sessionId: body.cashfree?.paymentSessionId,
      );
}
