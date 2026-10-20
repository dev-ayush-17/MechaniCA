class JobOffer {
  const JobOffer({
    required this.id,
    required this.bookingId,
    required this.serviceName,
    required this.vehicleType,
    required this.distanceKm,
    required this.totalPaise,
    required this.expiresAt,
    required this.attempt,
  });

  final String id;
  final String bookingId;
  final String serviceName;
  final String vehicleType;
  final double distanceKm;
  final int totalPaise;
  final DateTime expiresAt;
  final int attempt;
}
