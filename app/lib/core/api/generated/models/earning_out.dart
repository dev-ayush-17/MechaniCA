// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'earning_out.g.dart';

@JsonSerializable()
class EarningOut {
  const EarningOut({
    required this.bookingId,
    required this.displayNumber,
    required this.paidAt,
    required this.payoutStatus,
    required this.sharePaise,
    required this.totalPaise,
  });
  
  factory EarningOut.fromJson(Map<String, Object?> json) => _$EarningOutFromJson(json);
  
  final String bookingId;
  final String displayNumber;
  final DateTime paidAt;
  final String payoutStatus;
  final int sharePaise;
  final int totalPaise;

  Map<String, Object?> toJson() => _$EarningOutToJson(this);
}
