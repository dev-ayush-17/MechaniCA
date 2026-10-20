// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mechanic_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MechanicListOut _$MechanicListOutFromJson(Map<String, dynamic> json) =>
    MechanicListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => MechanicOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MechanicListOutToJson(MechanicListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
