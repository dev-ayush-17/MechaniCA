import '../../../core/error/result.dart';
import '../domain/payment.dart';
import '../domain/payment_api.dart';

/// In-memory gateway. Create stays pending until a test calls [markPaid].
class FakePaymentApi implements PaymentApi {
  FakePaymentApi();

  final Map<String, Payment> rows = {};
  int _n = 0;

  @override
  Future<Result<Payment>> create({
    required String bookingId,
    required String method,
    required String idempotencyKey,
  }) async {
    final existing = rows[idempotencyKey];
    if (existing != null) return Ok(existing);
    _n += 1;
    final payment = Payment(
      id: 'pay_$_n',
      status: 'pending',
      method: method,
      amountPaise: 76464,
      sessionId: 'sess_$_n',
    );
    rows[idempotencyKey] = payment;
    rows[payment.id] = payment;
    return Ok(payment);
  }

  @override
  Future<Result<Payment>> get(String paymentId) async {
    final row = rows[paymentId];
    if (row == null) return const Err(NotFound('We could not find that payment.'));
    return Ok(row);
  }

  void markPaid(String paymentId) {
    final row = rows[paymentId];
    if (row == null) return;
    final paid = Payment(
      id: row.id,
      status: 'paid',
      method: row.method,
      amountPaise: row.amountPaise,
      sessionId: row.sessionId,
    );
    rows[paymentId] = paid;
    for (final entry in rows.entries.toList()) {
      if (entry.value.id == paymentId) rows[entry.key] = paid;
    }
  }
}
