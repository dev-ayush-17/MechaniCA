// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EarningsListOut _$EarningsListOutFromJson(Map<String, dynamic> json) =>
    EarningsListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => EarningOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      notice: json['notice'] as String? ??
          'Recorded earnings. Bank payout is not live yet.',
    );

Map<String, dynamic> _$EarningsListOutToJson(EarningsListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
      'notice': instance.notice,
    };
