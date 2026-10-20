// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_booking_out.g.dart';

@JsonSerializable()
class AdminBookingOut {
  const AdminBookingOut({
    required this.city,
    required this.createdAt,
    required this.customerId,
    required this.displayNumber,
    required this.id,
    required this.status,
    required this.totalPaise,
  });
  
  factory AdminBookingOut.fromJson(Map<String, Object?> json) => _$AdminBookingOutFromJson(json);
  
  final String city;
  final DateTime createdAt;
  final String customerId;
  final String displayNumber;
  final String id;
  final String status;
  final int totalPaise;

  Map<String, Object?> toJson() => _$AdminBookingOutToJson(this);
}
