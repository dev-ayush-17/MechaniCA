// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'address_out.g.dart';

@JsonSerializable()
class AddressOut {
  const AddressOut({
    required this.city,
    required this.id,
    required this.isDefault,
    required this.label,
    required this.lat,
    required this.line1,
    required this.lng,
    required this.ownerId,
    required this.pincode,
    this.landmark,
  });
  
  factory AddressOut.fromJson(Map<String, Object?> json) => _$AddressOutFromJson(json);
  
  final String city;
  final String id;
  final bool isDefault;
  final String label;
  final String? landmark;
  final num lat;
  final String line1;
  final num lng;
  final String ownerId;
  final String pincode;

  Map<String, Object?> toJson() => _$AddressOutToJson(this);
}
