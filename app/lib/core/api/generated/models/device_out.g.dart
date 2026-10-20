// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceOut _$DeviceOutFromJson(Map<String, dynamic> json) => DeviceOut(
      platform: json['platform'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DeviceOutToJson(DeviceOut instance) => <String, dynamic>{
      'platform': instance.platform,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
