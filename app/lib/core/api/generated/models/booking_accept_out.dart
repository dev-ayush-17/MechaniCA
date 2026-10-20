// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'booking_accept_out.g.dart';

@JsonSerializable()
class BookingAcceptOut {
  const BookingAcceptOut({
    required this.id,
    required this.mechanicId,
    required this.status,
    required this.version,
  });
  
  factory BookingAcceptOut.fromJson(Map<String, Object?> json) => _$BookingAcceptOutFromJson(json);
  
  final String id;
  final String? mechanicId;
  final String status;
  final int version;

  Map<String, Object?> toJson() => _$BookingAcceptOutToJson(this);
}
