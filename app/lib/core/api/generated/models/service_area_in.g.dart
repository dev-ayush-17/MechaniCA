// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_area_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAreaIn _$ServiceAreaInFromJson(Map<String, dynamic> json) =>
    ServiceAreaIn(
      lat: json['lat'] as num,
      lng: json['lng'] as num,
      radiusKm: json['radiusKm'] as num,
    );

Map<String, dynamic> _$ServiceAreaInToJson(ServiceAreaIn instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'radiusKm': instance.radiusKm,
    };
