// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cancel_booking_request.g.dart';

@JsonSerializable()
class CancelBookingRequest {
  const CancelBookingRequest({
    this.reason = 'Cancelled',
  });
  
  factory CancelBookingRequest.fromJson(Map<String, Object?> json) => _$CancelBookingRequestFromJson(json);
  
  final String reason;

  Map<String, Object?> toJson() => _$CancelBookingRequestToJson(this);
}
