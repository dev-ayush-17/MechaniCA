// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cancel_request.g.dart';

@JsonSerializable()
class CancelRequest {
  const CancelRequest({
    this.reason = 'Cancelled',
  });
  
  factory CancelRequest.fromJson(Map<String, Object?> json) => _$CancelRequestFromJson(json);
  
  final String reason;

  Map<String, Object?> toJson() => _$CancelRequestToJson(this);
}
