// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentOut _$PaymentOutFromJson(Map<String, dynamic> json) => PaymentOut(
      amountPaise: (json['amountPaise'] as num).toInt(),
      method: json['method'] as String,
      paymentId: json['paymentId'] as String,
      status: json['status'] as String,
      cashfree: json['cashfree'] == null
          ? null
          : CashfreeSessionOut.fromJson(
              json['cashfree'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PaymentOutToJson(PaymentOut instance) =>
    <String, dynamic>{
      'amountPaise': instance.amountPaise,
      'cashfree': instance.cashfree,
      'method': instance.method,
      'paymentId': instance.paymentId,
      'status': instance.status,
    };
