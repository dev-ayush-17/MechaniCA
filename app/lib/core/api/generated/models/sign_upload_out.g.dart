// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_upload_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUploadOut _$SignUploadOutFromJson(Map<String, dynamic> json) =>
    SignUploadOut(
      uploadUrl: json['uploadUrl'] as String,
      path: json['path'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
    );

Map<String, dynamic> _$SignUploadOutToJson(SignUploadOut instance) =>
    <String, dynamic>{
      'uploadUrl': instance.uploadUrl,
      'path': instance.path,
      'headers': instance.headers,
    };
