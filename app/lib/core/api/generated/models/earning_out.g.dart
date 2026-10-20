// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EarningOut _$EarningOutFromJson(Map<String, dynamic> json) => EarningOut(
      bookingId: json['bookingId'] as String,
      displayNumber: json['displayNumber'] as String,
      paidAt: DateTime.parse(json['paidAt'] as String),
      payoutStatus: json['payoutStatus'] as String,
      sharePaise: (json['sharePaise'] as num).toInt(),
      totalPaise: (json['totalPaise'] as num).toInt(),
    );

Map<String, dynamic> _$EarningOutToJson(EarningOut instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'displayNumber': instance.displayNumber,
      'paidAt': instance.paidAt.toIso8601String(),
      'payoutStatus': instance.payoutStatus,
      'sharePaise': instance.sharePaise,
      'totalPaise': instance.totalPaise,
    };
