// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_upload_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUploadRequest _$SignUploadRequestFromJson(Map<String, dynamic> json) =>
    SignUploadRequest(
      contentType: json['contentType'] as String,
      maxBytes: (json['maxBytes'] as num).toInt(),
      path: json['path'] as String,
    );

Map<String, dynamic> _$SignUploadRequestToJson(SignUploadRequest instance) =>
    <String, dynamic>{
      'contentType': instance.contentType,
      'maxBytes': instance.maxBytes,
      'path': instance.path,
    };
