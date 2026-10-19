// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'line_decision_request_decision.dart';

part 'line_decision_request.g.dart';

@JsonSerializable()
class LineDecisionRequest {
  const LineDecisionRequest({
    required this.decision,
  });
  
  factory LineDecisionRequest.fromJson(Map<String, Object?> json) => _$LineDecisionRequestFromJson(json);
  
  final LineDecisionRequestDecision decision;

  Map<String, Object?> toJson() => _$LineDecisionRequestToJson(this);
}
