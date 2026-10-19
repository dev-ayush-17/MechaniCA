// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundRequest _$RefundRequestFromJson(Map<String, dynamic> json) =>
    RefundRequest(
      amountPaise: (json['amountPaise'] as num).toInt(),
      paymentId: json['paymentId'] as String,
    );

Map<String, dynamic> _$RefundRequestToJson(RefundRequest instance) =>
    <String, dynamic>{
      'amountPaise': instance.amountPaise,
      'paymentId': instance.paymentId,
    };
