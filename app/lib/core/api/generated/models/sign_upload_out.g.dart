// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_upload_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignUploadOut _$SignUploadOutFromJson(Map<String, dynamic> json) =>
    SignUploadOut(
      headers: Map<String, String>.from(json['headers'] as Map),
      path: json['path'] as String,
      uploadUrl: json['uploadUrl'] as String,
    );

Map<String, dynamic> _$SignUploadOutToJson(SignUploadOut instance) =>
    <String, dynamic>{
      'headers': instance.headers,
      'path': instance.path,
      'uploadUrl': instance.uploadUrl,
    };
