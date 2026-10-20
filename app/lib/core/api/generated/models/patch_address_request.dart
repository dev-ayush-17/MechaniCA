// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'patch_address_request.g.dart';

@JsonSerializable()
class PatchAddressRequest {
  const PatchAddressRequest({
    this.city,
    this.isDefault,
    this.label,
    this.landmark,
    this.lat,
    this.line1,
    this.lng,
    this.pincode,
  });
  
  factory PatchAddressRequest.fromJson(Map<String, Object?> json) => _$PatchAddressRequestFromJson(json);
  
  final String? city;
  final bool? isDefault;
  final String? label;
  final String? landmark;
  final num? lat;
  final String? line1;
  final num? lng;
  final String? pincode;

  Map<String, Object?> toJson() => _$PatchAddressRequestToJson(this);
}
