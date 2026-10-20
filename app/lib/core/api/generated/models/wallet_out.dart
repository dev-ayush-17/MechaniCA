// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'ledger_item_out.dart';

part 'wallet_out.g.dart';

@JsonSerializable()
class WalletOut {
  const WalletOut({
    required this.balancePaise,
    required this.items,
  });
  
  factory WalletOut.fromJson(Map<String, Object?> json) => _$WalletOutFromJson(json);
  
  final int balancePaise;
  final List<LedgerItemOut> items;

  Map<String, Object?> toJson() => _$WalletOutToJson(this);
}
