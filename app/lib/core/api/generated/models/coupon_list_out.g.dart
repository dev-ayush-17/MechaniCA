// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponListOut _$CouponListOutFromJson(Map<String, dynamic> json) =>
    CouponListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => CouponOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CouponListOutToJson(CouponListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
