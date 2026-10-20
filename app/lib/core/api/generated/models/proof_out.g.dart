// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProofOut _$ProofOutFromJson(Map<String, dynamic> json) => ProofOut(
      bookingId: json['bookingId'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      headers: Map<String, String>.from(json['headers'] as Map),
      hidden: json['hidden'] as bool,
      id: json['id'] as String,
      kind: json['kind'] as String,
      lineId: json['lineId'] as String,
      metadata: Map<String, String>.from(json['metadata'] as Map),
      path: json['path'] as String,
      uploadUrl: json['uploadUrl'] as String?,
    );

Map<String, dynamic> _$ProofOutToJson(ProofOut instance) => <String, dynamic>{
      'bookingId': instance.bookingId,
      'capturedAt': instance.capturedAt.toIso8601String(),
      'headers': instance.headers,
      'hidden': instance.hidden,
      'id': instance.id,
      'kind': instance.kind,
      'lineId': instance.lineId,
      'metadata': instance.metadata,
      'path': instance.path,
      'uploadUrl': instance.uploadUrl,
    };
