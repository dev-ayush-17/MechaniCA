// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_decision_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineDecisionRequest _$LineDecisionRequestFromJson(Map<String, dynamic> json) =>
    LineDecisionRequest(
      decision:
          LineDecisionRequestDecision.fromJson(json['decision'] as String),
    );

Map<String, dynamic> _$LineDecisionRequestToJson(
        LineDecisionRequest instance) =>
    <String, dynamic>{
      'decision': _$LineDecisionRequestDecisionEnumMap[instance.decision]!,
    };

const _$LineDecisionRequestDecisionEnumMap = {
  LineDecisionRequestDecision.approve: 'approve',
  LineDecisionRequestDecision.reject: 'reject',
  LineDecisionRequestDecision.$unknown: r'$unknown',
};
