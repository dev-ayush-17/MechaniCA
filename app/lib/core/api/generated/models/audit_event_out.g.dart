// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_event_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEventOut _$AuditEventOutFromJson(Map<String, dynamic> json) =>
    AuditEventOut(
      action: json['action'] as String,
      actorId: json['actorId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      role: json['role'] as String,
      summary: json['summary'] as String,
      targetId: json['targetId'] as String,
      targetType: json['targetType'] as String,
    );

Map<String, dynamic> _$AuditEventOutToJson(AuditEventOut instance) =>
    <String, dynamic>{
      'action': instance.action,
      'actorId': instance.actorId,
      'createdAt': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'requestId': instance.requestId,
      'role': instance.role,
      'summary': instance.summary,
      'targetId': instance.targetId,
      'targetType': instance.targetType,
    };
