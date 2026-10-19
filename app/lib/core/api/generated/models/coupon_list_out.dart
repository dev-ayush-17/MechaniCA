// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'coupon_out.dart';

part 'coupon_list_out.g.dart';

@JsonSerializable()
class CouponListOut {
  const CouponListOut({
    required this.items,
  });
  
  factory CouponListOut.fromJson(Map<String, Object?> json) => _$CouponListOutFromJson(json);
  
  final List<CouponOut> items;

  Map<String, Object?> toJson() => _$CouponListOutToJson(this);
}
