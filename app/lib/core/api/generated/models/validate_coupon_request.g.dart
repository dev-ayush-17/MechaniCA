// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validate_coupon_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidateCouponRequest _$ValidateCouponRequestFromJson(
        Map<String, dynamic> json) =>
    ValidateCouponRequest(
      code: json['code'] as String,
      laborPaise: (json['laborPaise'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ValidateCouponRequestToJson(
        ValidateCouponRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'laborPaise': instance.laborPaise,
    };
