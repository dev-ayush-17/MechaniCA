// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationOut _$NotificationOutFromJson(Map<String, dynamic> json) =>
    NotificationOut(
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deepLink: json['deepLink'] as String,
      id: json['id'] as String,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      templateId: json['templateId'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$NotificationOutToJson(NotificationOut instance) =>
    <String, dynamic>{
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
      'deepLink': instance.deepLink,
      'id': instance.id,
      'readAt': instance.readAt?.toIso8601String(),
      'templateId': instance.templateId,
      'title': instance.title,
    };
