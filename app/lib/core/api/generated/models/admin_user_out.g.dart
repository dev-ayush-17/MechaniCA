// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserOut _$AdminUserOutFromJson(Map<String, dynamic> json) => AdminUserOut(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneE164: json['phoneE164'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$AdminUserOutToJson(AdminUserOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phoneE164': instance.phoneE164,
      'role': instance.role,
      'status': instance.status,
    };
