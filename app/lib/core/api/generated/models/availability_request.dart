// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'availability_request.g.dart';

@JsonSerializable()
class AvailabilityRequest {
  const AvailabilityRequest({
    required this.online,
  });
  
  factory AvailabilityRequest.fromJson(Map<String, Object?> json) => _$AvailabilityRequestFromJson(json);
  
  final bool online;

  Map<String, Object?> toJson() => _$AvailabilityRequestToJson(this);
}
