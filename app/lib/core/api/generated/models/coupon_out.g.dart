// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponOut _$CouponOutFromJson(Map<String, dynamic> json) => CouponOut(
      amount: (json['amount'] as num).toInt(),
      code: json['code'] as String,
      description: json['description'] as String,
      endsAt: DateTime.parse(json['endsAt'] as String),
      maxDiscountPaise: (json['maxDiscountPaise'] as num).toInt(),
      minLaborPaise: (json['minLaborPaise'] as num).toInt(),
      title: json['title'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$CouponOutToJson(CouponOut instance) => <String, dynamic>{
      'amount': instance.amount,
      'code': instance.code,
      'description': instance.description,
      'endsAt': instance.endsAt.toIso8601String(),
      'maxDiscountPaise': instance.maxDiscountPaise,
      'minLaborPaise': instance.minLaborPaise,
      'title': instance.title,
      'type': instance.type,
    };
