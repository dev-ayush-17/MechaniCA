import '../../../core/error/result.dart';
import '../../payments/domain/payment.dart';
import '../domain/wallet_api.dart';
import '../domain/wallet_snapshot.dart';

class FakeWalletApi implements WalletApi {
  FakeWalletApi({
    this.balancePaise = 0,
    List<WalletLedgerItem>? items,
  }) : items = List.of(items ?? const []);

  int balancePaise;
  final List<WalletLedgerItem> items;

  @override
  Future<Result<WalletSnapshot>> getWallet() async {
    return Ok(WalletSnapshot(balancePaise: balancePaise, items: items));
  }

  @override
  Future<Result<Payment>> topup({
    required int amountPaise,
    required String idempotencyKey,
  }) async {
    return Ok(
      Payment(
        id: 'top_$idempotencyKey',
        status: 'pending',
        method: 'upi',
        amountPaise: amountPaise,
        sessionId: 'sess_topup',
      ),
    );
  }
}
