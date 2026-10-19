// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleOut _$VehicleOutFromJson(Map<String, dynamic> json) => VehicleOut(
      brand: json['brand'] as String,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fuelType: json['fuelType'] as String?,
      id: json['id'] as String,
      isPrimary: json['isPrimary'] as bool,
      model: json['model'] as String,
      odometerKm: (json['odometerKm'] as num?)?.toInt(),
      ownerId: json['ownerId'] as String,
      registrationNumber: json['registrationNumber'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      vehicleType: json['vehicleType'] as String,
      version: (json['version'] as num).toInt(),
      year: (json['year'] as num).toInt(),
    );

Map<String, dynamic> _$VehicleOutToJson(VehicleOut instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'color': instance.color,
      'createdAt': instance.createdAt.toIso8601String(),
      'fuelType': instance.fuelType,
      'id': instance.id,
      'isPrimary': instance.isPrimary,
      'model': instance.model,
      'odometerKm': instance.odometerKm,
      'ownerId': instance.ownerId,
      'registrationNumber': instance.registrationNumber,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'vehicleType': instance.vehicleType,
      'version': instance.version,
      'year': instance.year,
    };
