// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceListOut _$ServiceListOutFromJson(Map<String, dynamic> json) =>
    ServiceListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => ServiceOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ServiceListOutToJson(ServiceListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
