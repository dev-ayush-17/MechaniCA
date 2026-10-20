// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_out.g.dart';

@JsonSerializable()
class UserOut {
  const UserOut({
    required this.createdAt,
    required this.id,
    required this.name,
    required this.phoneE164,
    required this.role,
    required this.status,
    required this.updatedAt,
    this.email,
    this.photoPath,
  });
  
  factory UserOut.fromJson(Map<String, Object?> json) => _$UserOutFromJson(json);
  
  final DateTime createdAt;
  final String? email;
  final String id;
  final String name;
  final String phoneE164;
  final String? photoPath;
  final String role;
  final String status;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$UserOutToJson(this);
}
