class MechanicEarning {
  const MechanicEarning({
    required this.bookingId,
    required this.displayNumber,
    required this.sharePaise,
    required this.totalPaise,
    required this.paidAt,
    required this.payoutStatus,
  });

  final String bookingId;
  final String displayNumber;
  final int sharePaise;
  final int totalPaise;
  final DateTime paidAt;
  final String payoutStatus;
}

class EarningsList {
  const EarningsList({
    required this.items,
    this.notice = 'Recorded earnings. Bank payout is not live yet.',
  });

  final List<MechanicEarning> items;
  final String notice;
}
