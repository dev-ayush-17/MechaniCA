// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sign_upload_request.g.dart';

@JsonSerializable()
class SignUploadRequest {
  const SignUploadRequest({
    required this.contentType,
    required this.maxBytes,
    required this.path,
  });
  
  factory SignUploadRequest.fromJson(Map<String, Object?> json) => _$SignUploadRequestFromJson(json);
  
  final String contentType;
  final int maxBytes;
  final String path;

  Map<String, Object?> toJson() => _$SignUploadRequestToJson(this);
}
