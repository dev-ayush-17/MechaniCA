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
    required this.registrationNumber,
    required this.year,
    this.isPrimary = false,
    this.vehicleType = VehicleType.twoWheeler,
    this.color,
    this.fuelType,
    this.odometerKm,
  });
  
  factory CreateVehicleRequest.fromJson(Map<String, Object?> json) => _$CreateVehicleRequestFromJson(json);
  
  final String brand;
  final String? color;
  final String? fuelType;
  final bool isPrimary;
  final String model;
  final int? odometerKm;
  final String registrationNumber;
  final VehicleType vehicleType;
  final int year;

  Map<String, Object?> toJson() => _$CreateVehicleRequestToJson(this);
}
