// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum BookingStatus {
  @JsonValue('requested')
  requested('requested'),
  @JsonValue('confirmed')
  confirmed('confirmed'),
  @JsonValue('mechanicAssigned')
  mechanicAssigned('mechanicAssigned'),
  @JsonValue('enRoute')
  enRoute('enRoute'),
  @JsonValue('arrived')
  arrived('arrived'),
  @JsonValue('inService')
  inService('inService'),
  @JsonValue('completed')
  completed('completed'),
  @JsonValue('paid')
  paid('paid'),
  @JsonValue('cancelled')
  cancelled('cancelled'),
  @JsonValue('failed')
  failed('failed'),
  @JsonValue('disputed')
  disputed('disputed'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BookingStatus(this.json);

  factory BookingStatus.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<BookingStatus> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
