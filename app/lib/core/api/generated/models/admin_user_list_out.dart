// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_user_out.dart';

part 'admin_user_list_out.g.dart';

@JsonSerializable()
class AdminUserListOut {
  const AdminUserListOut({
    required this.items,
  });
  
  factory AdminUserListOut.fromJson(Map<String, Object?> json) => _$AdminUserListOutFromJson(json);
  
  final List<AdminUserOut> items;

  Map<String, Object?> toJson() => _$AdminUserListOutToJson(this);
}
