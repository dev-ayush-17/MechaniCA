// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_vehicle_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateVehicleRequest _$CreateVehicleRequestFromJson(
        Map<String, dynamic> json) =>
    CreateVehicleRequest(
      brand: json['brand'] as String,
      model: json['model'] as String,
      registrationNumber: json['registrationNumber'] as String,
      year: (json['year'] as num).toInt(),
      isPrimary: json['isPrimary'] as bool? ?? false,
      vehicleType: json['vehicleType'] == null
          ? VehicleType.twoWheeler
          : VehicleType.fromJson(json['vehicleType'] as String),
      color: json['color'] as String?,
      fuelType: json['fuelType'] as String?,
      odometerKm: (json['odometerKm'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateVehicleRequestToJson(
        CreateVehicleRequest instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'color': instance.color,
      'fuelType': instance.fuelType,
      'isPrimary': instance.isPrimary,
      'model': instance.model,
      'odometerKm': instance.odometerKm,
      'registrationNumber': instance.registrationNumber,
      'vehicleType': _$VehicleTypeEnumMap[instance.vehicleType]!,
      'year': instance.year,
    };

const _$VehicleTypeEnumMap = {
  VehicleType.twoWheeler: 'two_wheeler',
  VehicleType.fourWheeler: 'four_wheeler',
  VehicleType.$unknown: r'$unknown',
};
