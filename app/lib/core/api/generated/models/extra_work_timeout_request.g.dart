// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extra_work_timeout_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtraWorkTimeoutRequest _$ExtraWorkTimeoutRequestFromJson(
        Map<String, dynamic> json) =>
    ExtraWorkTimeoutRequest(
      bookingId: json['bookingId'] as String,
      lineId: json['lineId'] as String,
    );

Map<String, dynamic> _$ExtraWorkTimeoutRequestToJson(
        ExtraWorkTimeoutRequest instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'lineId': instance.lineId,
    };
