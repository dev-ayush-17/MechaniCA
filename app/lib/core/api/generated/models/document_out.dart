// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'document_out.g.dart';

@JsonSerializable()
class DocumentOut {
  const DocumentOut({
    required this.id,
    required this.kind,
    required this.storagePath,
  });
  
  factory DocumentOut.fromJson(Map<String, Object?> json) => _$DocumentOutFromJson(json);
  
  final String id;
  final String kind;
  final String storagePath;

  Map<String, Object?> toJson() => _$DocumentOutToJson(this);
}
