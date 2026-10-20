// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_ok.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobOk _$JobOkFromJson(Map<String, dynamic> json) => JobOk(
      expired: (json['expired'] as num?)?.toInt() ?? 0,
      ok: json['ok'] as bool? ?? true,
    );

Map<String, dynamic> _$JobOkToJson(JobOk instance) => <String, dynamic>{
      'expired': instance.expired,
      'ok': instance.ok,
    };
