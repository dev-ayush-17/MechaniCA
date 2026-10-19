// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_out.dart';

part 'vehicle_list_out.g.dart';

@JsonSerializable()
class VehicleListOut {
  const VehicleListOut({
    required this.items,
  });
  
  factory VehicleListOut.fromJson(Map<String, Object?> json) => _$VehicleListOutFromJson(json);
  
  final List<VehicleOut> items;

  Map<String, Object?> toJson() => _$VehicleListOutToJson(this);
}
