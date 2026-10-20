// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_booking_out.dart';

part 'admin_booking_list_out.g.dart';

@JsonSerializable()
class AdminBookingListOut {
  const AdminBookingListOut({
    required this.items,
  });
  
  factory AdminBookingListOut.fromJson(Map<String, Object?> json) => _$AdminBookingListOutFromJson(json);
  
  final List<AdminBookingOut> items;

  Map<String, Object?> toJson() => _$AdminBookingListOutToJson(this);
}
