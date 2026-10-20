// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditListOut _$AuditListOutFromJson(Map<String, dynamic> json) => AuditListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => AuditEventOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AuditListOutToJson(AuditListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
