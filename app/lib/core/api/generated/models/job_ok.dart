// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'job_ok.g.dart';

@JsonSerializable()
class JobOk {
  const JobOk({
    this.expired = 0,
    this.ok = true,
  });
  
  factory JobOk.fromJson(Map<String, Object?> json) => _$JobOkFromJson(json);
  
  final int expired;
  final bool ok;

  Map<String, Object?> toJson() => _$JobOkToJson(this);
}
