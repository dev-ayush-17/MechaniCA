// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'booking_mode.dart';
import 'payment_method.dart';
import 'urgency.dart';

part 'create_booking_request.g.dart';

@JsonSerializable()
class CreateBookingRequest {
  const CreateBookingRequest({
    required this.addressId,
    required this.mode,
    required this.paymentMethod,
    required this.serviceCode,
    required this.vehicleId,
    this.scheduledStart,
    this.couponCode = '',
    this.urgency = Urgency.normal,
  });
  
  factory CreateBookingRequest.fromJson(Map<String, Object?> json) => _$CreateBookingRequestFromJson(json);
  
  final String addressId;
  final String couponCode;
  final BookingMode mode;
  final PaymentMethod paymentMethod;
  final DateTime? scheduledStart;
  final String serviceCode;
  final Urgency urgency;
  final String vehicleId;

  Map<String, Object?> toJson() => _$CreateBookingRequestToJson(this);
}
