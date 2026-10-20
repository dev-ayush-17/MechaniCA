// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispute_note_out.dart';

part 'dispute_out.g.dart';

@JsonSerializable()
class DisputeOut {
  const DisputeOut({
    required this.bookingId,
    required this.createdAt,
    required this.customerId,
    required this.id,
    required this.notes,
    required this.reason,
    required this.resolution,
    required this.resolutionAmountPaise,
    required this.resolutionNote,
    required this.status,
  });
  
  factory DisputeOut.fromJson(Map<String, Object?> json) => _$DisputeOutFromJson(json);
  
  final String bookingId;
  final DateTime createdAt;
  final String customerId;
  final String id;
  final List<DisputeNoteOut> notes;
  final String reason;
  final String? resolution;
  final int resolutionAmountPaise;
  final String resolutionNote;
  final String status;

  Map<String, Object?> toJson() => _$DisputeOutToJson(this);
}
