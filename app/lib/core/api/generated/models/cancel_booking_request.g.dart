// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_booking_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CancelBookingRequest _$CancelBookingRequestFromJson(
        Map<String, dynamic> json) =>
    CancelBookingRequest(
      reason: json['reason'] as String? ?? 'Cancelled',
    );

Map<String, dynamic> _$CancelBookingRequestToJson(
        CancelBookingRequest instance) =>
    <String, dynamic>{
      'reason': instance.reason,
    };
