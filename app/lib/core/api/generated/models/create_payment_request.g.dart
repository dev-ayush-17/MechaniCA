// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_payment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePaymentRequest _$CreatePaymentRequestFromJson(
        Map<String, dynamic> json) =>
    CreatePaymentRequest(
      bookingId: json['bookingId'] as String,
      method: PaymentMethod.fromJson(json['method'] as String),
    );

Map<String, dynamic> _$CreatePaymentRequestToJson(
        CreatePaymentRequest instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'method': _$PaymentMethodEnumMap[instance.method]!,
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.upi: 'upi',
  PaymentMethod.card: 'card',
  PaymentMethod.netbanking: 'netbanking',
  PaymentMethod.cash: 'cash',
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.$unknown: r'$unknown',
};
