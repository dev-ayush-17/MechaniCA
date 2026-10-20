// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'notification_out.g.dart';

@JsonSerializable()
class NotificationOut {
  const NotificationOut({
    required this.body,
    required this.createdAt,
    required this.deepLink,
    required this.id,
    required this.readAt,
    required this.templateId,
    required this.title,
  });
  
  factory NotificationOut.fromJson(Map<String, Object?> json) => _$NotificationOutFromJson(json);
  
  final String body;
  final DateTime createdAt;
  final String deepLink;
  final String id;
  final DateTime? readAt;
  final String templateId;
  final String title;

  Map<String, Object?> toJson() => _$NotificationOutToJson(this);
}
