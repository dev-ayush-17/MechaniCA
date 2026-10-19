// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'booking_out.dart';

part 'booking_list_out.g.dart';

@JsonSerializable()
class BookingListOut {
  const BookingListOut({
    required this.items,
  });
  
  factory BookingListOut.fromJson(Map<String, Object?> json) => _$BookingListOutFromJson(json);
  
  final List<BookingOut> items;

  Map<String, Object?> toJson() => _$BookingListOutToJson(this);
}
