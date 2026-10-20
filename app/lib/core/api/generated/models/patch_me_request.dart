// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'patch_me_request.g.dart';

@JsonSerializable()
class PatchMeRequest {
  const PatchMeRequest({
    this.email,
    this.name,
  });
  
  factory PatchMeRequest.fromJson(Map<String, Object?> json) => _$PatchMeRequestFromJson(json);
  
  final String? email;
  final String? name;

  Map<String, Object?> toJson() => _$PatchMeRequestToJson(this);
}
