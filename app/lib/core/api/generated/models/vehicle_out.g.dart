// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleOut _$VehicleOutFromJson(Map<String, dynamic> json) => VehicleOut(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      vehicleType: json['vehicleType'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      registrationNumber: json['registrationNumber'] as String,
      fuelType: json['fuelType'] as String?,
      color: json['color'] as String?,
      odometerKm: (json['odometerKm'] as num?)?.toInt(),
      isPrimary: json['isPrimary'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$VehicleOutToJson(VehicleOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'vehicleType': instance.vehicleType,
      'brand': instance.brand,
      'model': instance.model,
      'year': instance.year,
      'registrationNumber': instance.registrationNumber,
      'fuelType': instance.fuelType,
      'color': instance.color,
      'odometerKm': instance.odometerKm,
      'isPrimary': instance.isPrimary,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'version': instance.version,
    };
