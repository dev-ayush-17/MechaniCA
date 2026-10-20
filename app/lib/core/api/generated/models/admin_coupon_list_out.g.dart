// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_coupon_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCouponListOut _$AdminCouponListOutFromJson(Map<String, dynamic> json) =>
    AdminCouponListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => AdminCouponOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AdminCouponListOutToJson(AdminCouponListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
