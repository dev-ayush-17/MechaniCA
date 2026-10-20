// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'device_out.g.dart';

@JsonSerializable()
class DeviceOut {
  const DeviceOut({
    required this.platform,
    required this.updatedAt,
  });
  
  factory DeviceOut.fromJson(Map<String, Object?> json) => _$DeviceOutFromJson(json);
  
  final String platform;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$DeviceOutToJson(this);
}
