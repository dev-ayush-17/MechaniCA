// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_user_out.g.dart';

@JsonSerializable()
class AdminUserOut {
  const AdminUserOut({
    required this.id,
    required this.name,
    required this.phoneE164,
    required this.role,
    required this.status,
  });
  
  factory AdminUserOut.fromJson(Map<String, Object?> json) => _$AdminUserOutFromJson(json);
  
  final String id;
  final String name;
  final String phoneE164;
  final String role;
  final String status;

  Map<String, Object?> toJson() => _$AdminUserOutToJson(this);
}
