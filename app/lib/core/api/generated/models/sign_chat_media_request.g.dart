// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_chat_media_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignChatMediaRequest _$SignChatMediaRequestFromJson(
        Map<String, dynamic> json) =>
    SignChatMediaRequest(
      contentType: json['contentType'] as String,
      maxBytes: (json['maxBytes'] as num).toInt(),
    );

Map<String, dynamic> _$SignChatMediaRequestToJson(
        SignChatMediaRequest instance) =>
    <String, dynamic>{
      'contentType': instance.contentType,
      'maxBytes': instance.maxBytes,
    };
