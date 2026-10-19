// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingOut _$BookingOutFromJson(Map<String, dynamic> json) => BookingOut(
      cancelReason: json['cancelReason'] as String?,
      displayNumber: json['displayNumber'] as String,
      estimate: EstimateOut.fromJson(json['estimate'] as Map<String, dynamic>),
      id: json['id'] as String,
      mechanicId: json['mechanicId'] as String?,
      mode: json['mode'] as String,
      paymentMethod: json['paymentMethod'] as String,
      scheduledStart: json['scheduledStart'] == null
          ? null
          : DateTime.parse(json['scheduledStart'] as String),
      serviceCode: json['serviceCode'] as String,
      serviceName: json['serviceName'] as String,
      status: json['status'] as String,
      urgency: json['urgency'] as String,
      vehicleId: json['vehicleId'] as String,
      version: (json['version'] as num).toInt(),
      cancelFeePaise: (json['cancelFeePaise'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BookingOutToJson(BookingOut instance) =>
    <String, dynamic>{
      'cancelFeePaise': instance.cancelFeePaise,
      'cancelReason': instance.cancelReason,
      'displayNumber': instance.displayNumber,
      'estimate': instance.estimate,
      'id': instance.id,
      'mechanicId': instance.mechanicId,
      'mode': instance.mode,
      'paymentMethod': instance.paymentMethod,
      'scheduledStart': instance.scheduledStart?.toIso8601String(),
      'serviceCode': instance.serviceCode,
      'serviceName': instance.serviceName,
      'status': instance.status,
      'urgency': instance.urgency,
      'vehicleId': instance.vehicleId,
      'version': instance.version,
    };
