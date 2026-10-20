import '../../../models/booking_model.dart';
import '../../booking/domain/booking.dart';

const kHealthFromLastService =
    'Based on your last service. A full checkup will replace this.';

enum HealthBand { good, fair, poor }

class VehicleHealth {
  const VehicleHealth({
    required this.score,
    required this.band,
    this.lastServiceAt,
  });

  final int score;
  final HealthBand band;
  final DateTime? lastServiceAt;

  String get label => switch (band) {
        HealthBand.good => 'Good',
        HealthBand.fair => 'Fair',
        HealthBand.poor => 'Poor',
      };
}

DateTime? lastCompletedServiceAt(List<Booking> bookings) {
  DateTime? latest;
  for (final booking in bookings) {
    if (booking.status != BookingStatus.paid &&
        booking.status != BookingStatus.completed) {
      continue;
    }
    final at = booking.scheduledStart;
    if (at == null) continue;
    if (latest == null || at.isAfter(latest)) latest = at;
  }
  return latest;
}

VehicleHealth healthFromLastService(
  DateTime? lastServiceAt, {
  required DateTime now,
}) {
  if (lastServiceAt == null) {
    return const VehicleHealth(score: 40, band: HealthBand.poor);
  }
  final days = now.difference(lastServiceAt).inDays;
  if (days <= 90) {
    return VehicleHealth(
      score: 90,
      band: HealthBand.good,
      lastServiceAt: lastServiceAt,
    );
  }
  if (days <= 180) {
    return VehicleHealth(
      score: 70,
      band: HealthBand.fair,
      lastServiceAt: lastServiceAt,
    );
  }
  return VehicleHealth(
    score: 40,
    band: HealthBand.poor,
    lastServiceAt: lastServiceAt,
  );
}
