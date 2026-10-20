// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_coupon_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCouponOut _$AdminCouponOutFromJson(Map<String, dynamic> json) =>
    AdminCouponOut(
      active: json['active'] as bool,
      amount: (json['amount'] as num).toInt(),
      code: json['code'] as String,
      description: json['description'] as String,
      endsAt: DateTime.parse(json['endsAt'] as String),
      maxRedemptions: (json['maxRedemptions'] as num).toInt(),
      minLaborPaise: (json['minLaborPaise'] as num).toInt(),
      redemptionCount: (json['redemptionCount'] as num).toInt(),
      startsAt: DateTime.parse(json['startsAt'] as String),
      title: json['title'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$AdminCouponOutToJson(AdminCouponOut instance) =>
    <String, dynamic>{
      'active': instance.active,
      'amount': instance.amount,
      'code': instance.code,
      'description': instance.description,
      'endsAt': instance.endsAt.toIso8601String(),
      'maxRedemptions': instance.maxRedemptions,
      'minLaborPaise': instance.minLaborPaise,
      'redemptionCount': instance.redemptionCount,
      'startsAt': instance.startsAt.toIso8601String(),
      'title': instance.title,
      'type': instance.type,
    };
