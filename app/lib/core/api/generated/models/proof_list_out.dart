// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'proof_out.dart';

part 'proof_list_out.g.dart';

@JsonSerializable()
class ProofListOut {
  const ProofListOut({
    required this.items,
  });
  
  factory ProofListOut.fromJson(Map<String, Object?> json) => _$ProofListOutFromJson(json);
  
  final List<ProofOut> items;

  Map<String, Object?> toJson() => _$ProofListOutToJson(this);
}
