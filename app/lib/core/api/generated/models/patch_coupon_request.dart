// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'patch_coupon_request.g.dart';

@JsonSerializable()
class PatchCouponRequest {
  const PatchCouponRequest({
    this.amount,
    this.title,
  });
  
  factory PatchCouponRequest.fromJson(Map<String, Object?> json) => _$PatchCouponRequestFromJson(json);
  
  final int? amount;
  final String? title;

  Map<String, Object?> toJson() => _$PatchCouponRequestToJson(this);
}
