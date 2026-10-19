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
      year: (json['year'] as num).toInt(),
      registrationNumber: json['registrationNumber'] as String,
      fuelType: json['fuelType'] as String?,
      color: json['color'] as String?,
      odometerKm: (json['odometerKm'] as num?)?.toInt(),
      vehicleType: json['vehicleType'] == null
          ? VehicleType.twoWheeler
          : VehicleType.fromJson(json['vehicleType'] as String),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$CreateVehicleRequestToJson(
        CreateVehicleRequest instance) =>
    <String, dynamic>{
      'vehicleType': _$VehicleTypeEnumMap[instance.vehicleType]!,
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
