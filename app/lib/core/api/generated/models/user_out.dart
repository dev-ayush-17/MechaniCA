// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_out.g.dart';

@JsonSerializable()
class UserOut {
  const UserOut({
    required this.id,
    required this.role,
    required this.name,
    required this.phoneE164,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserOut.fromJson(Map<String, Object?> json) => _$UserOutFromJson(json);
  
  final String id;
  final String role;
  final String name;
  final String phoneE164;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$UserOutToJson(this);
}
