// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_coupon_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCouponRequest _$CreateCouponRequestFromJson(Map<String, dynamic> json) =>
    CreateCouponRequest(
      amount: (json['amount'] as num).toInt(),
      code: json['code'] as String,
      endsAt: DateTime.parse(json['endsAt'] as String),
      startsAt: DateTime.parse(json['startsAt'] as String),
      title: json['title'] as String,
      type: CouponType.fromJson(json['type'] as String),
      description: json['description'] as String? ?? '',
      firstBookingOnly: json['firstBookingOnly'] as bool? ?? false,
      maxDiscountPaise: (json['maxDiscountPaise'] as num?)?.toInt() ?? 0,
      maxRedemptions: (json['maxRedemptions'] as num?)?.toInt() ?? 1000,
      minLaborPaise: (json['minLaborPaise'] as num?)?.toInt() ?? 0,
      perUserLimit: (json['perUserLimit'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$CreateCouponRequestToJson(
        CreateCouponRequest instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'code': instance.code,
      'description': instance.description,
      'endsAt': instance.endsAt.toIso8601String(),
      'firstBookingOnly': instance.firstBookingOnly,
      'maxDiscountPaise': instance.maxDiscountPaise,
      'maxRedemptions': instance.maxRedemptions,
      'minLaborPaise': instance.minLaborPaise,
      'perUserLimit': instance.perUserLimit,
      'startsAt': instance.startsAt.toIso8601String(),
      'title': instance.title,
      'type': _$CouponTypeEnumMap[instance.type]!,
    };

const _$CouponTypeEnumMap = {
  CouponType.flat: 'flat',
  CouponType.percent: 'percent',
  CouponType.$unknown: r'$unknown',
};
