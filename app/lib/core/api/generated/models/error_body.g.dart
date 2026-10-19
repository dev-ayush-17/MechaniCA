// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorBody _$ErrorBodyFromJson(Map<String, dynamic> json) => ErrorBody(
      code: json['code'] as String,
      fields: json['fields'],
      message: json['message'] as String,
      requestId: json['requestId'] as String,
    );

Map<String, dynamic> _$ErrorBodyToJson(ErrorBody instance) => <String, dynamic>{
      'code': instance.code,
      'fields': instance.fields,
      'message': instance.message,
      'requestId': instance.requestId,
    };
