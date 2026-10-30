/// Opens the vendor checkout UI. The SDK result is not paid
/// (docs/prd/15-payments.md).
abstract interface class PaymentCheckout {
  Future<void> open({required String sessionId});
}

/// Default until a Cashfree Flutter SDK is bound in the composition root.
class StubPaymentCheckout implements PaymentCheckout {
  @override
  Future<void> open({required String sessionId}) async {}
}
