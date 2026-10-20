// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dispute_note_request.g.dart';

@JsonSerializable()
class DisputeNoteRequest {
  const DisputeNoteRequest({
    required this.note,
  });
  
  factory DisputeNoteRequest.fromJson(Map<String, Object?> json) => _$DisputeNoteRequestFromJson(json);
  
  final String note;

  Map<String, Object?> toJson() => _$DisputeNoteRequestToJson(this);
}
