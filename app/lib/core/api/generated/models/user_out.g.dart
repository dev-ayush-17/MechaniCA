// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserOut _$UserOutFromJson(Map<String, dynamic> json) => UserOut(
      createdAt: DateTime.parse(json['createdAt'] as String),
      id: json['id'] as String,
      name: json['name'] as String,
      phoneE164: json['phoneE164'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserOutToJson(UserOut instance) => <String, dynamic>{
      'createdAt': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'name': instance.name,
      'phoneE164': instance.phoneE164,
      'role': instance.role,
      'status': instance.status,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
