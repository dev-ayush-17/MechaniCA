import '../../../models/booking_model.dart';

class Booking {
  const Booking({
    required this.id,
    required this.displayNumber,
    required this.status,
    required this.serviceCode,
    required this.mode,
    required this.urgency,
    required this.totalPaise,
    required this.cancelFeePaise,
    required this.version,
  });

  final String id;
  final String displayNumber;
  final BookingStatus status;
  final String serviceCode;
  final String mode;
  final String urgency;
  final int totalPaise;
  final int cancelFeePaise;
  final int version;
}

BookingStatus bookingStatusFromApi(String value) {
  return BookingStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => BookingStatus.requested,
  );
}
