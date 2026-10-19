// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_proof_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateProofRequest _$CreateProofRequestFromJson(Map<String, dynamic> json) =>
    CreateProofRequest(
      kind: ProofKind.fromJson(json['kind'] as String),
    );

Map<String, dynamic> _$CreateProofRequestToJson(CreateProofRequest instance) =>
    <String, dynamic>{
      'kind': _$ProofKindEnumMap[instance.kind]!,
    };

const _$ProofKindEnumMap = {
  ProofKind.before: 'before',
  ProofKind.after: 'after',
  ProofKind.oldPart: 'old_part',
  ProofKind.$unknown: r'$unknown',
};
