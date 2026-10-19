// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_type.dart';

part 'create_vehicle_request.g.dart';

@JsonSerializable()
class CreateVehicleRequest {
  const CreateVehicleRequest({
    required this.brand,
    required this.model,
    required this.year,
    required this.registrationNumber,
    this.fuelType,
    this.color,
    this.odometerKm,
    this.vehicleType = VehicleType.twoWheeler,
    this.isPrimary = false,
  });
  
  factory CreateVehicleRequest.fromJson(Map<String, Object?> json) => _$CreateVehicleRequestFromJson(json);
  
  final VehicleType vehicleType;
  final String brand;
  final String model;
  final int year;
  final String registrationNumber;
  final String? fuelType;
  final String? color;
  final int? odometerKm;
  final bool isPrimary;

  Map<String, Object?> toJson() => _$CreateVehicleRequestToJson(this);
}
