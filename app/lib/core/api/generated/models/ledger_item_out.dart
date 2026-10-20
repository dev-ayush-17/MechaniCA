// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ledger_item_out.g.dart';

@JsonSerializable()
class LedgerItemOut {
  const LedgerItemOut({
    required this.amountPaise,
    required this.createdAt,
    required this.direction,
    required this.id,
    required this.reason,
  });
  
  factory LedgerItemOut.fromJson(Map<String, Object?> json) => _$LedgerItemOutFromJson(json);
  
  final int amountPaise;
  final DateTime createdAt;
  final String direction;
  final String id;
  final String reason;

  Map<String, Object?> toJson() => _$LedgerItemOutToJson(this);
}
