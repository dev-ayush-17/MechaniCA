// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_area_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAreaOut _$ServiceAreaOutFromJson(Map<String, dynamic> json) =>
    ServiceAreaOut(
      geohash: json['geohash'] as String,
      lat: json['lat'] as num,
      lng: json['lng'] as num,
      radiusKm: json['radiusKm'] as num,
    );

Map<String, dynamic> _$ServiceAreaOutToJson(ServiceAreaOut instance) =>
    <String, dynamic>{
      'geohash': instance.geohash,
      'lat': instance.lat,
      'lng': instance.lng,
      'radiusKm': instance.radiusKm,
    };
