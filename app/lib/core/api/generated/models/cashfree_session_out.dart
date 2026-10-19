// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cashfree_session_out.g.dart';

@JsonSerializable()
class CashfreeSessionOut {
  const CashfreeSessionOut({
    required this.orderId,
    required this.paymentSessionId,
  });
  
  factory CashfreeSessionOut.fromJson(Map<String, Object?> json) => _$CashfreeSessionOutFromJson(json);
  
  final String orderId;
  final String paymentSessionId;

  Map<String, Object?> toJson() => _$CashfreeSessionOutToJson(this);
}
