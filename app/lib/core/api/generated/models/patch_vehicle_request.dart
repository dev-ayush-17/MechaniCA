// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_type.dart';

part 'patch_vehicle_request.g.dart';

@JsonSerializable()
class PatchVehicleRequest {
  const PatchVehicleRequest({
    required this.version,
    this.vehicleType,
    this.brand,
    this.model,
    this.year,
    this.registrationNumber,
    this.fuelType,
    this.color,
    this.odometerKm,
    this.isPrimary,
  });
  
  factory PatchVehicleRequest.fromJson(Map<String, Object?> json) => _$PatchVehicleRequestFromJson(json);
  
  final int version;
  final VehicleType? vehicleType;
  final String? brand;
  final String? model;
  final int? year;
  final String? registrationNumber;
  final String? fuelType;
  final String? color;
  final int? odometerKm;
  final bool? isPrimary;

  Map<String, Object?> toJson() => _$PatchVehicleRequestToJson(this);
}
