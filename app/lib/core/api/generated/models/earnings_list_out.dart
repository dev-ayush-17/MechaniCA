// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'earning_out.dart';

part 'earnings_list_out.g.dart';

@JsonSerializable()
class EarningsListOut {
  const EarningsListOut({
    required this.items,
    this.notice = 'Recorded earnings. Bank payout is not live yet.',
  });
  
  factory EarningsListOut.fromJson(Map<String, Object?> json) => _$EarningsListOutFromJson(json);
  
  final List<EarningOut> items;
  final String notice;

  Map<String, Object?> toJson() => _$EarningsListOutToJson(this);
}
