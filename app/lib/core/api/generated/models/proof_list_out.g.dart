// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProofListOut _$ProofListOutFromJson(Map<String, dynamic> json) => ProofListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => ProofOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProofListOutToJson(ProofListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
