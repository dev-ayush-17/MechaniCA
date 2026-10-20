// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'revenue_out.g.dart';

@JsonSerializable()
class RevenueOut {
  const RevenueOut({
    required this.cashPaise,
    required this.gmvPaise,
    required this.jobCount,
    required this.onlinePaise,
    required this.refundsPaise,
  });
  
  factory RevenueOut.fromJson(Map<String, Object?> json) => _$RevenueOutFromJson(json);
  
  final int cashPaise;
  final int gmvPaise;
  final int jobCount;
  final int onlinePaise;
  final int refundsPaise;

  Map<String, Object?> toJson() => _$RevenueOutToJson(this);
}
