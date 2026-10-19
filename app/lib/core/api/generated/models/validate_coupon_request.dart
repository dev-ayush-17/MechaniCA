// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'validate_coupon_request.g.dart';

@JsonSerializable()
class ValidateCouponRequest {
  const ValidateCouponRequest({
    required this.code,
    this.laborPaise = 0,
  });
  
  factory ValidateCouponRequest.fromJson(Map<String, Object?> json) => _$ValidateCouponRequestFromJson(json);
  
  final String code;
  final int laborPaise;

  Map<String, Object?> toJson() => _$ValidateCouponRequestToJson(this);
}
