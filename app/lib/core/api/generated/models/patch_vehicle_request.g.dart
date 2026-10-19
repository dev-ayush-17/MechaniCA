// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_vehicle_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchVehicleRequest _$PatchVehicleRequestFromJson(Map<String, dynamic> json) =>
    PatchVehicleRequest(
      version: (json['version'] as num).toInt(),
      vehicleType: json['vehicleType'] == null
          ? null
          : VehicleType.fromJson(json['vehicleType'] as String),
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      year: (json['year'] as num?)?.toInt(),
      registrationNumber: json['registrationNumber'] as String?,
      fuelType: json['fuelType'] as String?,
      color: json['color'] as String?,
      odometerKm: (json['odometerKm'] as num?)?.toInt(),
      isPrimary: json['isPrimary'] as bool?,
    );

Map<String, dynamic> _$PatchVehicleRequestToJson(
        PatchVehicleRequest instance) =>
    <String, dynamic>{
      'version': instance.version,
      'vehicleType': _$VehicleTypeEnumMap[instance.vehicleType],
      'brand': instance.brand,
      'model': instance.model,
      'year': instance.year,
      'registrationNumber': instance.registrationNumber,
      'fuelType': instance.fuelType,
      'color': instance.color,
      'odometerKm': instance.odometerKm,
      'isPrimary': instance.isPrimary,
    };

const _$VehicleTypeEnumMap = {
  VehicleType.twoWheeler: 'two_wheeler',
  VehicleType.fourWheeler: 'four_wheeler',
  VehicleType.$unknown: r'$unknown',
};
