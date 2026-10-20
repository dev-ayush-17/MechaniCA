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
      email: json['email'] as String?,
      photoPath: json['photoPath'] as String?,
    );

Map<String, dynamic> _$UserOutToJson(UserOut instance) => <String, dynamic>{
      'createdAt': instance.createdAt.toIso8601String(),
      'email': instance.email,
      'id': instance.id,
      'name': instance.name,
      'phoneE164': instance.phoneE164,
      'photoPath': instance.photoPath,
      'role': instance.role,
      'status': instance.status,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
