// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_create_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingCreateOut _$BookingCreateOutFromJson(Map<String, dynamic> json) =>
    BookingCreateOut(
      displayNumber: json['displayNumber'] as String,
      estimate: EstimateOut.fromJson(json['estimate'] as Map<String, dynamic>),
      id: json['id'] as String,
      mode: json['mode'] as String,
      serviceCode: json['serviceCode'] as String,
      status: json['status'] as String,
      urgency: json['urgency'] as String,
      version: (json['version'] as num).toInt(),
      cancelFeePaise: (json['cancelFeePaise'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BookingCreateOutToJson(BookingCreateOut instance) =>
    <String, dynamic>{
      'cancelFeePaise': instance.cancelFeePaise,
      'displayNumber': instance.displayNumber,
      'estimate': instance.estimate,
      'id': instance.id,
      'mode': instance.mode,
      'serviceCode': instance.serviceCode,
      'status': instance.status,
      'urgency': instance.urgency,
      'version': instance.version,
    };
