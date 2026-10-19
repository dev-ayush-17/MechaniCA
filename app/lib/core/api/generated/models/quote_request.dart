// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'quote_request.g.dart';

@JsonSerializable()
class QuoteRequest {
  const QuoteRequest({
    required this.serviceCode,
    required this.vehicleId,
    this.couponCode = '',
  });
  
  factory QuoteRequest.fromJson(Map<String, Object?> json) => _$QuoteRequestFromJson(json);
  
  final String couponCode;
  final String serviceCode;
  final String vehicleId;

  Map<String, Object?> toJson() => _$QuoteRequestToJson(this);
}
