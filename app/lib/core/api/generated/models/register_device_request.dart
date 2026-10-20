// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_device_request.g.dart';

@JsonSerializable()
class RegisterDeviceRequest {
  const RegisterDeviceRequest({
    required this.platform,
    required this.token,
  });
  
  factory RegisterDeviceRequest.fromJson(Map<String, Object?> json) => _$RegisterDeviceRequestFromJson(json);
  
  final String platform;
  final String token;

  Map<String, Object?> toJson() => _$RegisterDeviceRequestToJson(this);
}
