// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_out.dart';

part 'notification_list_out.g.dart';

@JsonSerializable()
class NotificationListOut {
  const NotificationListOut({
    required this.items,
  });
  
  factory NotificationListOut.fromJson(Map<String, Object?> json) => _$NotificationListOutFromJson(json);
  
  final List<NotificationOut> items;

  Map<String, Object?> toJson() => _$NotificationListOutToJson(this);
}
