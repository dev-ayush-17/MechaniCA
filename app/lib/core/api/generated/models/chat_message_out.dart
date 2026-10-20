// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'chat_message_out.g.dart';

@JsonSerializable()
class ChatMessageOut {
  const ChatMessageOut({
    required this.bookingId,
    required this.createdAt,
    required this.id,
    required this.mediaPath,
    required this.senderId,
    required this.senderRole,
    required this.state,
    required this.text,
  });
  
  factory ChatMessageOut.fromJson(Map<String, Object?> json) => _$ChatMessageOutFromJson(json);
  
  final String bookingId;
  final DateTime createdAt;
  final String id;
  final String? mediaPath;
  final String senderId;
  final String senderRole;
  final String state;
  final String? text;

  Map<String, Object?> toJson() => _$ChatMessageOutToJson(this);
}
