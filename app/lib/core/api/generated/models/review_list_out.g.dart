// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewListOut _$ReviewListOutFromJson(Map<String, dynamic> json) =>
    ReviewListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => ReviewOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      ratingAvg: json['ratingAvg'] as num,
      ratingCount: (json['ratingCount'] as num).toInt(),
    );

Map<String, dynamic> _$ReviewListOutToJson(ReviewListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
      'ratingAvg': instance.ratingAvg,
      'ratingCount': instance.ratingCount,
    };
