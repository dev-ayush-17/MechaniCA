// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'refund_request.g.dart';

@JsonSerializable()
class RefundRequest {
  const RefundRequest({
    required this.amountPaise,
    required this.paymentId,
  });
  
  factory RefundRequest.fromJson(Map<String, Object?> json) => _$RefundRequestFromJson(json);
  
  final int amountPaise;
  final String paymentId;

  Map<String, Object?> toJson() => _$RefundRequestToJson(this);
}
