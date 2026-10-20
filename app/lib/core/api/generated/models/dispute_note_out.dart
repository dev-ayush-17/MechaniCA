// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dispute_note_out.g.dart';

@JsonSerializable()
class DisputeNoteOut {
  const DisputeNoteOut({
    required this.actorId,
    required this.body,
    required this.createdAt,
  });
  
  factory DisputeNoteOut.fromJson(Map<String, Object?> json) => _$DisputeNoteOutFromJson(json);
  
  final String actorId;
  final String body;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$DisputeNoteOutToJson(this);
}
