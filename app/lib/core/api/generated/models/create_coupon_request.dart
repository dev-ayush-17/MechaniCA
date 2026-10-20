// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'coupon_type.dart';

part 'create_coupon_request.g.dart';

@JsonSerializable()
class CreateCouponRequest {
  const CreateCouponRequest({
    required this.amount,
    required this.code,
    required this.endsAt,
    required this.startsAt,
    required this.title,
    required this.type,
    this.description = '',
    this.firstBookingOnly = false,
    this.maxDiscountPaise = 0,
    this.maxRedemptions = 1000,
    this.minLaborPaise = 0,
    this.perUserLimit = 1,
  });
  
  factory CreateCouponRequest.fromJson(Map<String, Object?> json) => _$CreateCouponRequestFromJson(json);
  
  final int amount;
  final String code;
  final String description;
  final DateTime endsAt;
  final bool firstBookingOnly;
  final int maxDiscountPaise;
  final int maxRedemptions;
  final int minLaborPaise;
  final int perUserLimit;
  final DateTime startsAt;
  final String title;
  final CouponType type;

  Map<String, Object?> toJson() => _$CreateCouponRequestToJson(this);
}
