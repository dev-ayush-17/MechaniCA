// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'service_out.g.dart';

@JsonSerializable()
class ServiceOut {
  const ServiceOut({
    required this.active,
    required this.baseLaborPaise,
    required this.code,
    required this.description,
    required this.durationMin,
    required this.name,
    required this.sortOrder,
  });
  
  factory ServiceOut.fromJson(Map<String, Object?> json) => _$ServiceOutFromJson(json);
  
  final bool active;
  final int baseLaborPaise;
  final String code;
  final String description;
  final int durationMin;
  final String name;
  final int sortOrder;

  Map<String, Object?> toJson() => _$ServiceOutToJson(this);
}
