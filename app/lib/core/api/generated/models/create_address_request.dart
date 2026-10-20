// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_address_request.g.dart';

@JsonSerializable()
class CreateAddressRequest {
  const CreateAddressRequest({
    required this.city,
    required this.label,
    required this.lat,
    required this.line1,
    required this.lng,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
  });
  
  factory CreateAddressRequest.fromJson(Map<String, Object?> json) => _$CreateAddressRequestFromJson(json);
  
  final String city;
  final bool isDefault;
  final String label;
  final String? landmark;
  final num lat;
  final String line1;
  final num lng;
  final String pincode;

  Map<String, Object?> toJson() => _$CreateAddressRequestToJson(this);
}
