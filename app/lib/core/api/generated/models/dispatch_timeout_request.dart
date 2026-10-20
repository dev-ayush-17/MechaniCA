// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dispatch_timeout_request.g.dart';

@JsonSerializable()
class DispatchTimeoutRequest {
  const DispatchTimeoutRequest({
    required this.offerId,
  });
  
  factory DispatchTimeoutRequest.fromJson(Map<String, Object?> json) => _$DispatchTimeoutRequestFromJson(json);
  
  final String offerId;

  Map<String, Object?> toJson() => _$DispatchTimeoutRequestToJson(this);
}
