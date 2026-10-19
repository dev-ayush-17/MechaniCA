// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceOut _$ServiceOutFromJson(Map<String, dynamic> json) => ServiceOut(
      active: json['active'] as bool,
      baseLaborPaise: (json['baseLaborPaise'] as num).toInt(),
      code: json['code'] as String,
      description: json['description'] as String,
      durationMin: (json['durationMin'] as num).toInt(),
      name: json['name'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceOutToJson(ServiceOut instance) =>
    <String, dynamic>{
      'active': instance.active,
      'baseLaborPaise': instance.baseLaborPaise,
      'code': instance.code,
      'description': instance.description,
      'durationMin': instance.durationMin,
      'name': instance.name,
      'sortOrder': instance.sortOrder,
    };
