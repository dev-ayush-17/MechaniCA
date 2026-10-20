// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_quote_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponQuoteOut _$CouponQuoteOutFromJson(Map<String, dynamic> json) =>
    CouponQuoteOut(
      code: json['code'] as String,
      discountPaise: (json['discountPaise'] as num).toInt(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$CouponQuoteOutToJson(CouponQuoteOut instance) =>
    <String, dynamic>{
      'code': instance.code,
      'discountPaise': instance.discountPaise,
      'message': instance.message,
    };
