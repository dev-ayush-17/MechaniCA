import '../../../core/api/generated/models/create_vehicle_request.dart';
import '../../../core/api/generated/models/patch_vehicle_request.dart';
import '../../../core/api/generated/models/vehicle_out.dart';
import '../../../core/api/generated/models/vehicle_type.dart' as api;
import '../domain/vehicle.dart';

Vehicle vehicleFromDto(VehicleOut dto) => Vehicle(
      id: dto.id,
      ownerId: dto.ownerId,
      vehicleType: vehicleTypeFromApi(dto.vehicleType),
      brand: dto.brand,
      model: dto.model,
      year: dto.year,
      registrationNumber: dto.registrationNumber,
      fuelType: dto.fuelType,
      color: dto.color,
      odometerKm: dto.odometerKm,
      isPrimary: dto.isPrimary,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      version: dto.version,
    );

CreateVehicleRequest createRequestFrom(Vehicle vehicle) => CreateVehicleRequest(
      vehicleType: vehicle.vehicleType == VehicleType.fourWheeler
          ? api.VehicleType.fourWheeler
          : api.VehicleType.twoWheeler,
      brand: vehicle.brand,
      model: vehicle.model,
      year: vehicle.year,
      registrationNumber: vehicle.registrationNumber,
      fuelType: vehicle.fuelType,
      color: vehicle.color,
      odometerKm: vehicle.odometerKm,
      isPrimary: vehicle.isPrimary,
    );

PatchVehicleRequest patchRequestFrom(Vehicle vehicle) => PatchVehicleRequest(
      version: vehicle.version,
      vehicleType: vehicle.vehicleType == VehicleType.fourWheeler
          ? api.VehicleType.fourWheeler
          : api.VehicleType.twoWheeler,
      brand: vehicle.brand,
      model: vehicle.model,
      year: vehicle.year,
      registrationNumber: vehicle.registrationNumber,
      fuelType: vehicle.fuelType,
      color: vehicle.color,
      odometerKm: vehicle.odometerKm,
      isPrimary: vehicle.isPrimary,
    );

Map<String, dynamic> vehiclePayload(Vehicle vehicle) => {
      'id': vehicle.id,
      'ownerId': vehicle.ownerId,
      'vehicleType': vehicleTypeToApi(vehicle.vehicleType),
      'brand': vehicle.brand,
      'model': vehicle.model,
      'year': vehicle.year,
      'registrationNumber': vehicle.registrationNumber,
      'fuelType': vehicle.fuelType,
      'color': vehicle.color,
      'odometerKm': vehicle.odometerKm,
      'isPrimary': vehicle.isPrimary,
      'version': vehicle.version,
    };
