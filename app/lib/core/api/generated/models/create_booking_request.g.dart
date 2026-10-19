// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_booking_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBookingRequest _$CreateBookingRequestFromJson(
        Map<String, dynamic> json) =>
    CreateBookingRequest(
      addressId: json['addressId'] as String,
      mode: BookingMode.fromJson(json['mode'] as String),
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
      serviceCode: json['serviceCode'] as String,
      vehicleId: json['vehicleId'] as String,
      scheduledStart: json['scheduledStart'] == null
          ? null
          : DateTime.parse(json['scheduledStart'] as String),
      couponCode: json['couponCode'] as String? ?? '',
      urgency: json['urgency'] == null
          ? Urgency.normal
          : Urgency.fromJson(json['urgency'] as String),
    );

Map<String, dynamic> _$CreateBookingRequestToJson(
        CreateBookingRequest instance) =>
    <String, dynamic>{
      'addressId': instance.addressId,
      'couponCode': instance.couponCode,
      'mode': _$BookingModeEnumMap[instance.mode]!,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'scheduledStart': instance.scheduledStart?.toIso8601String(),
      'serviceCode': instance.serviceCode,
      'urgency': _$UrgencyEnumMap[instance.urgency]!,
      'vehicleId': instance.vehicleId,
    };

const _$BookingModeEnumMap = {
  BookingMode.instant: 'instant',
  BookingMode.scheduled: 'scheduled',
  BookingMode.$unknown: r'$unknown',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.upi: 'upi',
  PaymentMethod.card: 'card',
  PaymentMethod.netbanking: 'netbanking',
  PaymentMethod.cash: 'cash',
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.$unknown: r'$unknown',
};

const _$UrgencyEnumMap = {
  Urgency.normal: 'normal',
  Urgency.sos: 'sos',
  Urgency.$unknown: r'$unknown',
};
