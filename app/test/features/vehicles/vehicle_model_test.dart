import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/features/vehicles/domain/bike_mapper.dart';
import 'package:mechupp_app/features/vehicles/domain/vehicle.dart';
import 'package:mechupp_app/models/bike_model.dart';

void main() {
  test('vehicle_mapper_round_trip_preserves_registration', () {
    final bike = BikeModel(
      id: 'v1',
      userId: 'u1',
      name: 'Hero Splendor',
      brand: 'Hero',
      model: 'Splendor',
      registrationNumber: 'BR01AB1234',
      year: 2020,
      fuelType: 'petrol',
      odometer: 100,
      color: 'Red',
      isPrimary: true,
      addedAt: DateTime(2024, 1, 1),
    );
    final vehicle = bike.toVehicle();
    expect(vehicle.hasValidPlate, isTrue);
    expect(vehicle.toBikeModel().registrationNumber, 'BR01AB1234');
  });

  test('vehicle_rejects_invalid_plate', () {
    final vehicle = Vehicle(
      id: 'v1',
      ownerId: 'u1',
      vehicleType: VehicleType.twoWheeler,
      brand: 'TVS',
      model: 'Apache',
      year: 2022,
      registrationNumber: 'BR80Y 024',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
    expect(vehicle.hasValidPlate, isFalse);
  });
}
