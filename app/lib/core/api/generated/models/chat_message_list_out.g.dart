// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageListOut _$ChatMessageListOutFromJson(Map<String, dynamic> json) =>
    ChatMessageListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => ChatMessageOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChatMessageListOutToJson(ChatMessageListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
