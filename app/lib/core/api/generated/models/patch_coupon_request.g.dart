// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_coupon_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchCouponRequest _$PatchCouponRequestFromJson(Map<String, dynamic> json) =>
    PatchCouponRequest(
      amount: (json['amount'] as num?)?.toInt(),
      title: json['title'] as String?,
    );

Map<String, dynamic> _$PatchCouponRequestToJson(PatchCouponRequest instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'title': instance.title,
    };
