// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorBody _$ErrorBodyFromJson(Map<String, dynamic> json) => ErrorBody(
      code: json['code'] as String,
      message: json['message'] as String,
      fields: json['fields'],
      requestId: json['requestId'] as String,
    );

Map<String, dynamic> _$ErrorBodyToJson(ErrorBody instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'fields': instance.fields,
      'requestId': instance.requestId,
    };
