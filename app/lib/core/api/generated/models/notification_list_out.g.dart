// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationListOut _$NotificationListOutFromJson(Map<String, dynamic> json) =>
    NotificationListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => NotificationOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NotificationListOutToJson(
        NotificationListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
