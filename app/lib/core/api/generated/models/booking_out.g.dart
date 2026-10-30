// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingOut _$BookingOutFromJson(Map<String, dynamic> json) => BookingOut(
      addressId: json['addressId'] as String,
      cancelReason: json['cancelReason'] as String?,
      displayNumber: json['displayNumber'] as String,
      estimate: EstimateOut.fromJson(json['estimate'] as Map<String, dynamic>),
      id: json['id'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => BookingLineOut.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      failureReason: json['failureReason'] as String?,
      cancelFeePaise: (json['cancelFeePaise'] as num?)?.toInt() ?? 0,
      dispatchAttempt: (json['dispatchAttempt'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BookingOutToJson(BookingOut instance) =>
    <String, dynamic>{
      'addressId': instance.addressId,
      'cancelFeePaise': instance.cancelFeePaise,
      'cancelReason': instance.cancelReason,
      'dispatchAttempt': instance.dispatchAttempt,
      'displayNumber': instance.displayNumber,
      'estimate': instance.estimate,
      'failureReason': instance.failureReason,
      'id': instance.id,
      'lines': instance.lines,
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
