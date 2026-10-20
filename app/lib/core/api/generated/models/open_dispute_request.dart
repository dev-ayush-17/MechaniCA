// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'open_dispute_request.g.dart';

@JsonSerializable()
class OpenDisputeRequest {
  const OpenDisputeRequest({
    required this.reason,
  });
  
  factory OpenDisputeRequest.fromJson(Map<String, Object?> json) => _$OpenDisputeRequestFromJson(json);
  
  final String reason;

  Map<String, Object?> toJson() => _$OpenDisputeRequestToJson(this);
}
