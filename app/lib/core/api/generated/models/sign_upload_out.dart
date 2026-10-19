// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sign_upload_out.g.dart';

@JsonSerializable()
class SignUploadOut {
  const SignUploadOut({
    required this.headers,
    required this.path,
    required this.uploadUrl,
  });
  
  factory SignUploadOut.fromJson(Map<String, Object?> json) => _$SignUploadOutFromJson(json);
  
  final Map<String, String> headers;
  final String path;
  final String uploadUrl;

  Map<String, Object?> toJson() => _$SignUploadOutToJson(this);
}
