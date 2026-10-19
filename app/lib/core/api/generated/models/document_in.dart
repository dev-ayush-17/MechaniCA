// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_kind.dart';

part 'document_in.g.dart';

@JsonSerializable()
class DocumentIn {
  const DocumentIn({
    required this.kind,
    required this.storagePath,
  });
  
  factory DocumentIn.fromJson(Map<String, Object?> json) => _$DocumentInFromJson(json);
  
  final DocumentKind kind;
  final String storagePath;

  Map<String, Object?> toJson() => _$DocumentInToJson(this);
}
