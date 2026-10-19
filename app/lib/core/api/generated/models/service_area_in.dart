// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'service_area_in.g.dart';

@JsonSerializable()
class ServiceAreaIn {
  const ServiceAreaIn({
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });
  
  factory ServiceAreaIn.fromJson(Map<String, Object?> json) => _$ServiceAreaInFromJson(json);
  
  final num lat;
  final num lng;
  final num radiusKm;

  Map<String, Object?> toJson() => _$ServiceAreaInToJson(this);
}
