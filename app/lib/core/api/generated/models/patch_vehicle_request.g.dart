// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_vehicle_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchVehicleRequest _$PatchVehicleRequestFromJson(Map<String, dynamic> json) =>
    PatchVehicleRequest(
      version: (json['version'] as num).toInt(),
      brand: json['brand'] as String?,
      color: json['color'] as String?,
      fuelType: json['fuelType'] as String?,
      isPrimary: json['isPrimary'] as bool?,
      model: json['model'] as String?,
      odometerKm: (json['odometerKm'] as num?)?.toInt(),
      registrationNumber: json['registrationNumber'] as String?,
      vehicleType: json['vehicleType'] == null
          ? null
          : VehicleType.fromJson(json['vehicleType'] as String),
      year: (json['year'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PatchVehicleRequestToJson(
        PatchVehicleRequest instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'color': instance.color,
      'fuelType': instance.fuelType,
      'isPrimary': instance.isPrimary,
      'model': instance.model,
      'odometerKm': instance.odometerKm,
      'registrationNumber': instance.registrationNumber,
      'vehicleType': _$VehicleTypeEnumMap[instance.vehicleType],
      'version': instance.version,
      'year': instance.year,
    };

const _$VehicleTypeEnumMap = {
  VehicleType.twoWheeler: 'two_wheeler',
  VehicleType.fourWheeler: 'four_wheeler',
  VehicleType.$unknown: r'$unknown',
};
