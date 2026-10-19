import 'package:freezed_annotation/freezed_annotation.dart';

import 'indian_plate.dart';

part 'vehicle.freezed.dart';

enum VehicleType { twoWheeler, fourWheeler }

@freezed
abstract class Vehicle with _$Vehicle {
  const Vehicle._();

  const factory Vehicle({
    required String id,
    required String ownerId,
    required VehicleType vehicleType,
    required String brand,
    required String model,
    required int year,
    required String registrationNumber,
    String? fuelType,
    String? color,
    int? odometerKm,
    @Default(false) bool isPrimary,
    String? insuranceExpiry,
    String? pucExpiry,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(1) int version,
  }) = _Vehicle;

  /// Display name for legacy bike UI copy.
  String get displayName => '$brand $model'.trim();

  String get normalizedPlate => normalizeIndianPlate(registrationNumber);

  bool get hasValidPlate => isValidIndianPlate(registrationNumber);
}

String vehicleTypeToApi(VehicleType type) => switch (type) {
      VehicleType.twoWheeler => 'two_wheeler',
      VehicleType.fourWheeler => 'four_wheeler',
    };

VehicleType vehicleTypeFromApi(String raw) => switch (raw) {
      'four_wheeler' => VehicleType.fourWheeler,
      _ => VehicleType.twoWheeler,
    };
