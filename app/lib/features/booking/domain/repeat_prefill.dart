import '../../../models/service_model.dart';
import '../../catalog/domain/service_definition.dart';
import 'booking.dart';

/// Vehicle, service, and address only. Never copies the old total.
class RepeatPrefill {
  const RepeatPrefill({
    required this.vehicleId,
    required this.serviceCode,
    required this.addressId,
  });

  factory RepeatPrefill.fromBooking(Booking booking) {
    return RepeatPrefill(
      vehicleId: booking.vehicleId,
      serviceCode: booking.serviceCode,
      addressId: booking.addressId,
    );
  }

  final String vehicleId;
  final String serviceCode;
  final String addressId;
}

ServiceModel serviceModelFromDefinition(ServiceDefinition svc) {
  return ServiceModel(
    id: svc.code,
    name: svc.name,
    description: svc.description,
    price: (svc.baseLaborPaise ~/ 100).toDouble(),
    iconName: 'build',
    category: 'service',
    duration: svc.durationLabel,
    isPopular: svc.code == 'general_service',
    includes: const [],
  );
}
