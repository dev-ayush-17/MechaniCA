// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'proof_kind.dart';

part 'create_proof_request.g.dart';

@JsonSerializable()
class CreateProofRequest {
  const CreateProofRequest({
    required this.kind,
  });
  
  factory CreateProofRequest.fromJson(Map<String, Object?> json) => _$CreateProofRequestFromJson(json);
  
  final ProofKind kind;

  Map<String, Object?> toJson() => _$CreateProofRequestToJson(this);
}
