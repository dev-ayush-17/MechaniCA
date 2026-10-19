// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'chat_message_out.dart';

part 'chat_message_list_out.g.dart';

@JsonSerializable()
class ChatMessageListOut {
  const ChatMessageListOut({
    required this.items,
  });
  
  factory ChatMessageListOut.fromJson(Map<String, Object?> json) => _$ChatMessageListOutFromJson(json);
  
  final List<ChatMessageOut> items;

  Map<String, Object?> toJson() => _$ChatMessageListOutToJson(this);
}
