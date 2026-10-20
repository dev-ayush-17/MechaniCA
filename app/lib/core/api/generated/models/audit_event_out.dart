// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'audit_event_out.g.dart';

@JsonSerializable()
class AuditEventOut {
  const AuditEventOut({
    required this.action,
    required this.actorId,
    required this.createdAt,
    required this.id,
    required this.requestId,
    required this.role,
    required this.summary,
    required this.targetId,
    required this.targetType,
  });
  
  factory AuditEventOut.fromJson(Map<String, Object?> json) => _$AuditEventOutFromJson(json);
  
  final String action;
  final String actorId;
  final DateTime createdAt;
  final String id;
  final String requestId;
  final String role;
  final String summary;
  final String targetId;
  final String targetType;

  Map<String, Object?> toJson() => _$AuditEventOutToJson(this);
}
