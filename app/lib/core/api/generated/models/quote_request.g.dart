// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteRequest _$QuoteRequestFromJson(Map<String, dynamic> json) => QuoteRequest(
      serviceCode: json['serviceCode'] as String,
      vehicleId: json['vehicleId'] as String,
      couponCode: json['couponCode'] as String? ?? '',
    );

Map<String, dynamic> _$QuoteRequestToJson(QuoteRequest instance) =>
    <String, dynamic>{
      'couponCode': instance.couponCode,
      'serviceCode': instance.serviceCode,
      'vehicleId': instance.vehicleId,
    };
