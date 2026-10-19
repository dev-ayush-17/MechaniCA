// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteOut _$QuoteOutFromJson(Map<String, dynamic> json) => QuoteOut(
      cgstPaise: (json['cgstPaise'] as num).toInt(),
      discountPaise: (json['discountPaise'] as num).toInt(),
      feePaise: (json['feePaise'] as num).toInt(),
      laborPaise: (json['laborPaise'] as num).toInt(),
      partsPaise: (json['partsPaise'] as num).toInt(),
      sgstPaise: (json['sgstPaise'] as num).toInt(),
      totalPaise: (json['totalPaise'] as num).toInt(),
    );

Map<String, dynamic> _$QuoteOutToJson(QuoteOut instance) => <String, dynamic>{
      'cgstPaise': instance.cgstPaise,
      'discountPaise': instance.discountPaise,
      'feePaise': instance.feePaise,
      'laborPaise': instance.laborPaise,
      'partsPaise': instance.partsPaise,
      'sgstPaise': instance.sgstPaise,
      'totalPaise': instance.totalPaise,
    };
