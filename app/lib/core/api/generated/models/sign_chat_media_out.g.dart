// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_chat_media_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignChatMediaOut _$SignChatMediaOutFromJson(Map<String, dynamic> json) =>
    SignChatMediaOut(
      headers: Map<String, String>.from(json['headers'] as Map),
      path: json['path'] as String,
      uploadUrl: json['uploadUrl'] as String,
    );

Map<String, dynamic> _$SignChatMediaOutToJson(SignChatMediaOut instance) =>
    <String, dynamic>{
      'headers': instance.headers,
      'path': instance.path,
      'uploadUrl': instance.uploadUrl,
    };
