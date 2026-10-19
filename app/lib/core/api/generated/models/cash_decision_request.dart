// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cash_decision_request.g.dart';

@JsonSerializable()
class CashDecisionRequest {
  const CashDecisionRequest({
    this.paid = true,
  });
  
  factory CashDecisionRequest.fromJson(Map<String, Object?> json) => _$CashDecisionRequestFromJson(json);
  
  final bool paid;

  Map<String, Object?> toJson() => _$CashDecisionRequestToJson(this);
}
