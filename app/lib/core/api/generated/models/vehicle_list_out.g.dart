// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleListOut _$VehicleListOutFromJson(Map<String, dynamic> json) =>
    VehicleListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => VehicleOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VehicleListOutToJson(VehicleListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
