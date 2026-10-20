class Payment {
  const Payment({
    required this.id,
    required this.status,
    required this.method,
    required this.amountPaise,
    this.sessionId,
  });

  final String id;
  final String status;
  final String method;
  final int amountPaise;
  final String? sessionId;

  bool get isPaid => status == 'paid';
}
