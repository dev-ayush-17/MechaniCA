// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_method.dart';

part 'create_payment_request.g.dart';

@JsonSerializable()
class CreatePaymentRequest {
  const CreatePaymentRequest({
    required this.bookingId,
    required this.method,
  });
  
  factory CreatePaymentRequest.fromJson(Map<String, Object?> json) => _$CreatePaymentRequestFromJson(json);
  
  final String bookingId;
  final PaymentMethod method;

  Map<String, Object?> toJson() => _$CreatePaymentRequestToJson(this);
}
