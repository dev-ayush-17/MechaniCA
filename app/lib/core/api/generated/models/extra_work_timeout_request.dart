// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'extra_work_timeout_request.g.dart';

@JsonSerializable()
class ExtraWorkTimeoutRequest {
  const ExtraWorkTimeoutRequest({
    required this.bookingId,
    required this.lineId,
  });
  
  factory ExtraWorkTimeoutRequest.fromJson(Map<String, Object?> json) => _$ExtraWorkTimeoutRequestFromJson(json);
  
  final String bookingId;
  final String lineId;

  Map<String, Object?> toJson() => _$ExtraWorkTimeoutRequestToJson(this);
}
