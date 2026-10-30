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
    this.vehicleId = '',
    this.serviceName = '',
    this.addressId = '',
    this.scheduledStart,
    this.paymentMethod = '',
    this.mechanicId,
    this.mechanicName,
    this.mechanicRatingAvg,
    this.mechanicRatingCount = 0,
    this.dispatchAttempt = 0,
    this.failureReason,
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
  final String vehicleId;
  final String serviceName;
  final String addressId;
  final DateTime? scheduledStart;
  final String paymentMethod;
  final String? mechanicId;
  final String? mechanicName;
  final double? mechanicRatingAvg;
  final int mechanicRatingCount;
  final int dispatchAttempt;
  final String? failureReason;
}

BookingStatus bookingStatusFromApi(String value) {
  return BookingStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => BookingStatus.requested,
  );
}
