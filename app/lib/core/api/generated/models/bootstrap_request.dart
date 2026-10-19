// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'intent.dart';

part 'bootstrap_request.g.dart';

/// `role` is deliberately not a field: the server derives it from `intent`.
@JsonSerializable()
class BootstrapRequest {
  const BootstrapRequest({
    required this.intent,
    this.name,
  });
  
  factory BootstrapRequest.fromJson(Map<String, Object?> json) => _$BootstrapRequestFromJson(json);
  
  final Intent intent;
  final String? name;

  Map<String, Object?> toJson() => _$BootstrapRequestToJson(this);
}
