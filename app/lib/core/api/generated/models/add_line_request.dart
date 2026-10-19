// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'line_kind.dart';

part 'add_line_request.g.dart';

@JsonSerializable()
class AddLineRequest {
  const AddLineRequest({
    required this.amountPaise,
    required this.name,
    this.kind = LineKind.valuePart,
  });
  
  factory AddLineRequest.fromJson(Map<String, Object?> json) => _$AddLineRequestFromJson(json);
  
  final int amountPaise;
  final LineKind kind;
  final String name;

  Map<String, Object?> toJson() => _$AddLineRequestToJson(this);
}
