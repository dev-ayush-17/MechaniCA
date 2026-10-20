// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'public_tracking_out.g.dart';

@JsonSerializable()
class PublicTrackingOut {
  const PublicTrackingOut({
    required this.destLat,
    required this.destLng,
    required this.etaSeconds,
    required this.mechanicFirstName,
    required this.mechanicLat,
    required this.mechanicLng,
    required this.status,
    required this.vehicleLabel,
  });
  
  factory PublicTrackingOut.fromJson(Map<String, Object?> json) => _$PublicTrackingOutFromJson(json);
  
  final num destLat;
  final num destLng;
  final int? etaSeconds;
  final String mechanicFirstName;
  final num? mechanicLat;
  final num? mechanicLng;
  final String status;
  final String vehicleLabel;

  Map<String, Object?> toJson() => _$PublicTrackingOutToJson(this);
}
