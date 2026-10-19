// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'service_area_out.g.dart';

@JsonSerializable()
class ServiceAreaOut {
  const ServiceAreaOut({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.geohash,
  });
  
  factory ServiceAreaOut.fromJson(Map<String, Object?> json) => _$ServiceAreaOutFromJson(json);
  
  final num lat;
  final num lng;
  final num radiusKm;
  final String geohash;

  Map<String, Object?> toJson() => _$ServiceAreaOutToJson(this);
}
