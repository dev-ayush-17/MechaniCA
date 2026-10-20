// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeListOut _$DisputeListOutFromJson(Map<String, dynamic> json) =>
    DisputeListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => DisputeOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DisputeListOutToJson(DisputeListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
