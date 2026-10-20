import '../../../core/error/result.dart';
import '../../payments/domain/payment.dart';
import 'wallet_snapshot.dart';

/// FastAPI wallet ledger and Cashfree top-up.
abstract class WalletApi {
  Future<Result<WalletSnapshot>> getWallet();

  Future<Result<Payment>> topup({
    required int amountPaise,
    required String idempotencyKey,
  });
}
