// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletOut _$WalletOutFromJson(Map<String, dynamic> json) => WalletOut(
      balancePaise: (json['balancePaise'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => LedgerItemOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WalletOutToJson(WalletOut instance) => <String, dynamic>{
      'balancePaise': instance.balancePaise,
      'items': instance.items,
    };
