// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'booking_line_out.dart';
import 'estimate_out.dart';

part 'booking_out.g.dart';

@JsonSerializable()
class BookingOut {
  const BookingOut({
    required this.cancelReason,
    required this.displayNumber,
    required this.estimate,
    required this.id,
    required this.lines,
    required this.mechanicId,
    required this.mode,
    required this.paymentMethod,
    required this.scheduledStart,
    required this.serviceCode,
    required this.serviceName,
    required this.status,
    required this.urgency,
    required this.vehicleId,
    required this.version,
    this.cancelFeePaise = 0,
  });
  
  factory BookingOut.fromJson(Map<String, Object?> json) => _$BookingOutFromJson(json);
  
  final int cancelFeePaise;
  final String? cancelReason;
  final String displayNumber;
  final EstimateOut estimate;
  final String id;
  final List<BookingLineOut> lines;
  final String? mechanicId;
  final String mode;
  final String paymentMethod;
  final DateTime? scheduledStart;
  final String serviceCode;
  final String serviceName;
  final String status;
  final String urgency;
  final String vehicleId;
  final int version;

  Map<String, Object?> toJson() => _$BookingOutToJson(this);
}
