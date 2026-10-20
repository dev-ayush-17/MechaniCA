// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'suspension_request.g.dart';

@JsonSerializable()
class SuspensionRequest {
  const SuspensionRequest({
    required this.reason,
  });
  
  factory SuspensionRequest.fromJson(Map<String, Object?> json) => _$SuspensionRequestFromJson(json);
  
  final String reason;

  Map<String, Object?> toJson() => _$SuspensionRequestToJson(this);
}
