// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevenueOut _$RevenueOutFromJson(Map<String, dynamic> json) => RevenueOut(
      cashPaise: (json['cashPaise'] as num).toInt(),
      gmvPaise: (json['gmvPaise'] as num).toInt(),
      jobCount: (json['jobCount'] as num).toInt(),
      onlinePaise: (json['onlinePaise'] as num).toInt(),
      refundsPaise: (json['refundsPaise'] as num).toInt(),
    );

Map<String, dynamic> _$RevenueOutToJson(RevenueOut instance) =>
    <String, dynamic>{
      'cashPaise': instance.cashPaise,
      'gmvPaise': instance.gmvPaise,
      'jobCount': instance.jobCount,
      'onlinePaise': instance.onlinePaise,
      'refundsPaise': instance.refundsPaise,
    };
