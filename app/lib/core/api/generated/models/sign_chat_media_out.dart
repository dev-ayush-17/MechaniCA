// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sign_chat_media_out.g.dart';

@JsonSerializable()
class SignChatMediaOut {
  const SignChatMediaOut({
    required this.headers,
    required this.path,
    required this.uploadUrl,
  });
  
  factory SignChatMediaOut.fromJson(Map<String, Object?> json) => _$SignChatMediaOutFromJson(json);
  
  final Map<String, String> headers;
  final String path;
  final String uploadUrl;

  Map<String, Object?> toJson() => _$SignChatMediaOutToJson(this);
}
