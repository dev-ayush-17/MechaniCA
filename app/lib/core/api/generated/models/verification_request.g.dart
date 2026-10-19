// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationRequest _$VerificationRequestFromJson(Map<String, dynamic> json) =>
    VerificationRequest(
      decision: VerificationDecision.fromJson(json['decision'] as String),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$VerificationRequestToJson(
        VerificationRequest instance) =>
    <String, dynamic>{
      'decision': _$VerificationDecisionEnumMap[instance.decision]!,
      'reason': instance.reason,
    };

const _$VerificationDecisionEnumMap = {
  VerificationDecision.approve: 'approve',
  VerificationDecision.reject: 'reject',
  VerificationDecision.$unknown: r'$unknown',
};
