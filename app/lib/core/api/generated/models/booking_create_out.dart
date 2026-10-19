// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'estimate_out.dart';

part 'booking_create_out.g.dart';

@JsonSerializable()
class BookingCreateOut {
  const BookingCreateOut({
    required this.displayNumber,
    required this.estimate,
    required this.id,
    required this.mode,
    required this.serviceCode,
    required this.status,
    required this.urgency,
    required this.version,
    this.cancelFeePaise = 0,
  });
  
  factory BookingCreateOut.fromJson(Map<String, Object?> json) => _$BookingCreateOutFromJson(json);
  
  final int cancelFeePaise;
  final String displayNumber;
  final EstimateOut estimate;
  final String id;
  final String mode;
  final String serviceCode;
  final String status;
  final String urgency;
  final int version;

  Map<String, Object?> toJson() => _$BookingCreateOutToJson(this);
}
