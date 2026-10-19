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
    this.brand,
    this.color,
    this.fuelType,
    this.isPrimary,
    this.model,
    this.odometerKm,
    this.registrationNumber,
    this.vehicleType,
    this.year,
  });
  
  factory PatchVehicleRequest.fromJson(Map<String, Object?> json) => _$PatchVehicleRequestFromJson(json);
  
  final String? brand;
  final String? color;
  final String? fuelType;
  final bool? isPrimary;
  final String? model;
  final int? odometerKm;
  final String? registrationNumber;
  final VehicleType? vehicleType;
  final int version;
  final int? year;

  Map<String, Object?> toJson() => _$PatchVehicleRequestToJson(this);
}
