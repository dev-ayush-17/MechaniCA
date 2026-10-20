// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_coupon_out.g.dart';

@JsonSerializable()
class AdminCouponOut {
  const AdminCouponOut({
    required this.active,
    required this.amount,
    required this.code,
    required this.description,
    required this.endsAt,
    required this.maxRedemptions,
    required this.minLaborPaise,
    required this.redemptionCount,
    required this.startsAt,
    required this.title,
    required this.type,
  });
  
  factory AdminCouponOut.fromJson(Map<String, Object?> json) => _$AdminCouponOutFromJson(json);
  
  final bool active;
  final int amount;
  final String code;
  final String description;
  final DateTime endsAt;
  final int maxRedemptions;
  final int minLaborPaise;
  final int redemptionCount;
  final DateTime startsAt;
  final String title;
  final String type;

  Map<String, Object?> toJson() => _$AdminCouponOutToJson(this);
}
