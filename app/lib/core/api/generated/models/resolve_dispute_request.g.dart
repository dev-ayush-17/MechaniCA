// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolve_dispute_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResolveDisputeRequest _$ResolveDisputeRequestFromJson(
        Map<String, dynamic> json) =>
    ResolveDisputeRequest(
      note: json['note'] as String,
      resolution: DisputeResolution.fromJson(json['resolution'] as String),
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ResolveDisputeRequestToJson(
        ResolveDisputeRequest instance) =>
    <String, dynamic>{
      'amountPaise': instance.amountPaise,
      'note': instance.note,
      'resolution': _$DisputeResolutionEnumMap[instance.resolution]!,
    };

const _$DisputeResolutionEnumMap = {
  DisputeResolution.refund: 'refund',
  DisputeResolution.noRefund: 'no_refund',
  DisputeResolution.cashWalletCredit: 'cash_wallet_credit',
  DisputeResolution.$unknown: r'$unknown',
};
