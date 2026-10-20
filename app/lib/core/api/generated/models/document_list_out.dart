// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_out.dart';

part 'document_list_out.g.dart';

@JsonSerializable()
class DocumentListOut {
  const DocumentListOut({
    required this.items,
  });
  
  factory DocumentListOut.fromJson(Map<String, Object?> json) => _$DocumentListOutFromJson(json);
  
  final List<DocumentOut> items;

  Map<String, Object?> toJson() => _$DocumentListOutToJson(this);
}
