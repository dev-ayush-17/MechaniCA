// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_upload_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUploadRequest _$SignUploadRequestFromJson(Map<String, dynamic> json) =>
    SignUploadRequest(
      path: json['path'] as String,
      contentType: json['contentType'] as String,
      maxBytes: (json['maxBytes'] as num).toInt(),
    );

Map<String, dynamic> _$SignUploadRequestToJson(SignUploadRequest instance) =>
    <String, dynamic>{
      'path': instance.path,
      'contentType': instance.contentType,
      'maxBytes': instance.maxBytes,
    };
