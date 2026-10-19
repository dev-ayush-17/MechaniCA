import '../../../models/bike_model.dart';
import 'vehicle.dart';

/// Maps between the demo [BikeModel] and domain [Vehicle] during the bikes UI migration.
extension VehicleBikeMapper on Vehicle {
  BikeModel toBikeModel() => BikeModel(
        id: id,
        userId: ownerId,
        name: displayName,
        brand: brand,
        model: model,
        registrationNumber: registrationNumber,
        year: year,
        fuelType: fuelType ?? 'petrol',
        insuranceExpiry: insuranceExpiry,
        pucExpiry: pucExpiry,
        odometer: odometerKm ?? 0,
        color: color ?? '',
        isPrimary: isPrimary,
        addedAt: createdAt,
      );
}

extension BikeVehicleMapper on BikeModel {
  Vehicle toVehicle() => Vehicle(
        id: id,
        ownerId: userId,
        vehicleType: VehicleType.twoWheeler,
        brand: brand,
        model: model,
        year: year,
        registrationNumber: registrationNumber,
        fuelType: fuelType,
        color: color,
        odometerKm: odometer,
        isPrimary: isPrimary,
        insuranceExpiry: insuranceExpiry,
        pucExpiry: pucExpiry,
        createdAt: addedAt,
        updatedAt: addedAt,
      );
}
