// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle_out.g.dart';

@JsonSerializable()
class VehicleOut {
  const VehicleOut({
    required this.id,
    required this.ownerId,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.registrationNumber,
    required this.fuelType,
    required this.color,
    required this.odometerKm,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });
  
  factory VehicleOut.fromJson(Map<String, Object?> json) => _$VehicleOutFromJson(json);
  
  final String id;
  final String ownerId;
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final String registrationNumber;
  final String? fuelType;
  final String? color;
  final int? odometerKm;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Map<String, Object?> toJson() => _$VehicleOutToJson(this);
}
