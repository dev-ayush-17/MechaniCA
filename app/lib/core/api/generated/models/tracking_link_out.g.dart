// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_link_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackingLinkOut _$TrackingLinkOutFromJson(Map<String, dynamic> json) =>
    TrackingLinkOut(
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      path: json['path'] as String,
      token: json['token'] as String,
    );

Map<String, dynamic> _$TrackingLinkOutToJson(TrackingLinkOut instance) =>
    <String, dynamic>{
      'expiresAt': instance.expiresAt.toIso8601String(),
      'path': instance.path,
      'token': instance.token,
    };
