// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_coupon_out.dart';

part 'admin_coupon_list_out.g.dart';

@JsonSerializable()
class AdminCouponListOut {
  const AdminCouponListOut({
    required this.items,
  });
  
  factory AdminCouponListOut.fromJson(Map<String, Object?> json) => _$AdminCouponListOutFromJson(json);
  
  final List<AdminCouponOut> items;

  Map<String, Object?> toJson() => _$AdminCouponListOutToJson(this);
}
