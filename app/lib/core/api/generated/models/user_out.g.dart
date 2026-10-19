// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserOut _$UserOutFromJson(Map<String, dynamic> json) => UserOut(
      id: json['id'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      phoneE164: json['phoneE164'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserOutToJson(UserOut instance) => <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'name': instance.name,
      'phoneE164': instance.phoneE164,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
