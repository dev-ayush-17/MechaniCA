// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum VehicleType {
  @JsonValue('two_wheeler')
  twoWheeler('two_wheeler'),
  @JsonValue('four_wheeler')
  fourWheeler('four_wheeler'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const VehicleType(this.json);

  factory VehicleType.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<VehicleType> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
