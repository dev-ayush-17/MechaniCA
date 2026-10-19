// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'coupon_quote_out.g.dart';

@JsonSerializable()
class CouponQuoteOut {
  const CouponQuoteOut({
    required this.code,
    required this.discountPaise,
    required this.message,
  });
  
  factory CouponQuoteOut.fromJson(Map<String, Object?> json) => _$CouponQuoteOutFromJson(json);
  
  final String code;
  final int discountPaise;
  final String message;

  Map<String, Object?> toJson() => _$CouponQuoteOutToJson(this);
}
