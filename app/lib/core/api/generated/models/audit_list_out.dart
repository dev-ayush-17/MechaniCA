// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'audit_event_out.dart';

part 'audit_list_out.g.dart';

@JsonSerializable()
class AuditListOut {
  const AuditListOut({
    required this.items,
  });
  
  factory AuditListOut.fromJson(Map<String, Object?> json) => _$AuditListOutFromJson(json);
  
  final List<AuditEventOut> items;

  Map<String, Object?> toJson() => _$AuditListOutToJson(this);
}
