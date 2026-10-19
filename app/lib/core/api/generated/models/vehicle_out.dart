// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle_out.g.dart';

@JsonSerializable()
class VehicleOut {
  const VehicleOut({
    required this.brand,
    required this.color,
    required this.createdAt,
    required this.fuelType,
    required this.id,
    required this.isPrimary,
    required this.model,
    required this.odometerKm,
    required this.ownerId,
    required this.registrationNumber,
    required this.updatedAt,
    required this.vehicleType,
    required this.version,
    required this.year,
  });
  
  factory VehicleOut.fromJson(Map<String, Object?> json) => _$VehicleOutFromJson(json);
  
  final String brand;
  final String? color;
  final DateTime createdAt;
  final String? fuelType;
  final String id;
  final bool isPrimary;
  final String model;
  final int? odometerKm;
  final String ownerId;
  final String registrationNumber;
  final DateTime updatedAt;
  final String vehicleType;
  final int version;
  final int year;

  Map<String, Object?> toJson() => _$VehicleOutToJson(this);
}
