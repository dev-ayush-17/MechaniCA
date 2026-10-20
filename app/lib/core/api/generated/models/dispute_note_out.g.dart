// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_note_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeNoteOut _$DisputeNoteOutFromJson(Map<String, dynamic> json) =>
    DisputeNoteOut(
      actorId: json['actorId'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DisputeNoteOutToJson(DisputeNoteOut instance) =>
    <String, dynamic>{
      'actorId': instance.actorId,
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
    };
