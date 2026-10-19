// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'booking_line_out.g.dart';

@JsonSerializable()
class BookingLineOut {
  const BookingLineOut({
    required this.amountPaise,
    required this.gstPaise,
    required this.id,
    required this.kind,
    required this.name,
    required this.status,
  });
  
  factory BookingLineOut.fromJson(Map<String, Object?> json) => _$BookingLineOutFromJson(json);
  
  final int amountPaise;
  final int gstPaise;
  final String id;
  final String kind;
  final String name;
  final String status;

  Map<String, Object?> toJson() => _$BookingLineOutToJson(this);
}
