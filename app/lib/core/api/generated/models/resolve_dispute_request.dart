// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispute_resolution.dart';

part 'resolve_dispute_request.g.dart';

@JsonSerializable()
class ResolveDisputeRequest {
  const ResolveDisputeRequest({
    required this.note,
    required this.resolution,
    this.amountPaise = 0,
  });
  
  factory ResolveDisputeRequest.fromJson(Map<String, Object?> json) => _$ResolveDisputeRequestFromJson(json);
  
  final int amountPaise;
  final String note;
  final DisputeResolution resolution;

  Map<String, Object?> toJson() => _$ResolveDisputeRequestToJson(this);
}
