// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'proof_out.g.dart';

@JsonSerializable()
class ProofOut {
  const ProofOut({
    required this.bookingId,
    required this.capturedAt,
    required this.headers,
    required this.hidden,
    required this.id,
    required this.kind,
    required this.lineId,
    required this.metadata,
    required this.path,
    this.uploadUrl,
  });
  
  factory ProofOut.fromJson(Map<String, Object?> json) => _$ProofOutFromJson(json);
  
  final String bookingId;
  final DateTime capturedAt;
  final Map<String, String> headers;
  final bool hidden;
  final String id;
  final String kind;
  final String lineId;
  final Map<String, String> metadata;
  final String path;
  final String? uploadUrl;

  Map<String, Object?> toJson() => _$ProofOutToJson(this);
}
