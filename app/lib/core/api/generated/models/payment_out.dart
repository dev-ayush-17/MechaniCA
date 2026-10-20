// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cashfree_session_out.dart';

part 'payment_out.g.dart';

@JsonSerializable()
class PaymentOut {
  const PaymentOut({
    required this.amountPaise,
    required this.method,
    required this.paymentId,
    required this.status,
    this.cashfree,
  });
  
  factory PaymentOut.fromJson(Map<String, Object?> json) => _$PaymentOutFromJson(json);
  
  final int amountPaise;
  final CashfreeSessionOut? cashfree;
  final String method;
  final String paymentId;
  final String status;

  Map<String, Object?> toJson() => _$PaymentOutToJson(this);
}
