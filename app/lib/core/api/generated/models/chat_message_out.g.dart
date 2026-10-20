// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageOut _$ChatMessageOutFromJson(Map<String, dynamic> json) =>
    ChatMessageOut(
      bookingId: json['bookingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      id: json['id'] as String,
      mediaPath: json['mediaPath'] as String?,
      senderId: json['senderId'] as String,
      senderRole: json['senderRole'] as String,
      state: json['state'] as String,
      text: json['text'] as String?,
    );

Map<String, dynamic> _$ChatMessageOutToJson(ChatMessageOut instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'createdAt': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'mediaPath': instance.mediaPath,
      'senderId': instance.senderId,
      'senderRole': instance.senderRole,
      'state': instance.state,
      'text': instance.text,
    };
