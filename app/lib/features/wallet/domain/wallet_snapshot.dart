class WalletLedgerItem {
  const WalletLedgerItem({
    required this.id,
    required this.reason,
    required this.amountPaise,
    required this.direction,
    required this.createdAt,
  });

  final String id;
  final String reason;
  final int amountPaise;
  final String direction;
  final DateTime createdAt;

  bool get isCredit => direction == 'credit';
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.balancePaise,
    required this.items,
  });

  final int balancePaise;
  final List<WalletLedgerItem> items;
}
