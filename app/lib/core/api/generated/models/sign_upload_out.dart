// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sign_upload_out.g.dart';

@JsonSerializable()
class SignUploadOut {
  const SignUploadOut({
    required this.uploadUrl,
    required this.path,
    required this.headers,
  });
  
  factory SignUploadOut.fromJson(Map<String, Object?> json) => _$SignUploadOutFromJson(json);
  
  final String uploadUrl;
  final String path;
  final Map<String, String> headers;

  Map<String, Object?> toJson() => _$SignUploadOutToJson(this);
}
