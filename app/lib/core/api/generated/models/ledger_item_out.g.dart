// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_item_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerItemOut _$LedgerItemOutFromJson(Map<String, dynamic> json) =>
    LedgerItemOut(
      amountPaise: (json['amountPaise'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      direction: json['direction'] as String,
      id: json['id'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$LedgerItemOutToJson(LedgerItemOut instance) =>
    <String, dynamic>{
      'amountPaise': instance.amountPaise,
      'createdAt': instance.createdAt.toIso8601String(),
      'direction': instance.direction,
      'id': instance.id,
      'reason': instance.reason,
    };
