// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sign_chat_media_request.g.dart';

@JsonSerializable()
class SignChatMediaRequest {
  const SignChatMediaRequest({
    required this.contentType,
    required this.maxBytes,
  });
  
  factory SignChatMediaRequest.fromJson(Map<String, Object?> json) => _$SignChatMediaRequestFromJson(json);
  
  final String contentType;
  final int maxBytes;

  Map<String, Object?> toJson() => _$SignChatMediaRequestToJson(this);
}
