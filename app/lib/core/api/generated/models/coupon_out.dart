// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'coupon_out.g.dart';

@JsonSerializable()
class CouponOut {
  const CouponOut({
    required this.amount,
    required this.code,
    required this.description,
    required this.endsAt,
    required this.maxDiscountPaise,
    required this.minLaborPaise,
    required this.title,
    required this.type,
  });
  
  factory CouponOut.fromJson(Map<String, Object?> json) => _$CouponOutFromJson(json);
  
  final int amount;
  final String code;
  final String description;
  final DateTime endsAt;
  final int maxDiscountPaise;
  final int minLaborPaise;
  final String title;
  final String type;

  Map<String, Object?> toJson() => _$CouponOutToJson(this);
}
