// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error_body.g.dart';

@JsonSerializable()
class ErrorBody {
  const ErrorBody({
    required this.code,
    required this.message,
    required this.fields,
    required this.requestId,
  });
  
  factory ErrorBody.fromJson(Map<String, Object?> json) => _$ErrorBodyFromJson(json);
  
  final String code;
  final String message;
  final dynamic fields;
  final String requestId;

  Map<String, Object?> toJson() => _$ErrorBodyToJson(this);
}
