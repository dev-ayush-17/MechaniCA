import '../../../core/error/result.dart';
import 'payment.dart';

/// FastAPI payments. The client never marks a row paid.
abstract class PaymentApi {
  Future<Result<Payment>> create({
    required String bookingId,
    required String method,
    required String idempotencyKey,
  });

  Future<Result<Payment>> get(String paymentId);
}
