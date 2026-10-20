// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserListOut _$AdminUserListOutFromJson(Map<String, dynamic> json) =>
    AdminUserListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => AdminUserOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AdminUserListOutToJson(AdminUserListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
