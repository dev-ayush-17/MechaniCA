// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'tracking_link_out.g.dart';

@JsonSerializable()
class TrackingLinkOut {
  const TrackingLinkOut({
    required this.expiresAt,
    required this.path,
    required this.token,
  });
  
  factory TrackingLinkOut.fromJson(Map<String, Object?> json) => _$TrackingLinkOutFromJson(json);
  
  final DateTime expiresAt;
  final String path;
  final String token;

  Map<String, Object?> toJson() => _$TrackingLinkOutToJson(this);
}
