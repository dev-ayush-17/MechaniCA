// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sign_upload_request.g.dart';

@JsonSerializable()
class SignUploadRequest {
  const SignUploadRequest({
    required this.path,
    required this.contentType,
    required this.maxBytes,
  });
  
  factory SignUploadRequest.fromJson(Map<String, Object?> json) => _$SignUploadRequestFromJson(json);
  
  final String path;
  final String contentType;
  final int maxBytes;

  Map<String, Object?> toJson() => _$SignUploadRequestToJson(this);
}
