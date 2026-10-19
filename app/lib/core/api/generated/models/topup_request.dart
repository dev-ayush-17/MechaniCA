// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'topup_request.g.dart';

@JsonSerializable()
class TopupRequest {
  const TopupRequest({
    required this.amountPaise,
  });
  
  factory TopupRequest.fromJson(Map<String, Object?> json) => _$TopupRequestFromJson(json);
  
  final int amountPaise;

  Map<String, Object?> toJson() => _$TopupRequestToJson(this);
}
