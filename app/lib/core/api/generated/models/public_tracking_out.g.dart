// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_tracking_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicTrackingOut _$PublicTrackingOutFromJson(Map<String, dynamic> json) =>
    PublicTrackingOut(
      destLat: json['destLat'] as num,
      destLng: json['destLng'] as num,
      etaSeconds: (json['etaSeconds'] as num?)?.toInt(),
      mechanicFirstName: json['mechanicFirstName'] as String,
      mechanicLat: json['mechanicLat'] as num?,
      mechanicLng: json['mechanicLng'] as num?,
      status: json['status'] as String,
      vehicleLabel: json['vehicleLabel'] as String,
    );

Map<String, dynamic> _$PublicTrackingOutToJson(PublicTrackingOut instance) =>
    <String, dynamic>{
      'destLat': instance.destLat,
      'destLng': instance.destLng,
      'etaSeconds': instance.etaSeconds,
      'mechanicFirstName': instance.mechanicFirstName,
      'mechanicLat': instance.mechanicLat,
      'mechanicLng': instance.mechanicLng,
      'status': instance.status,
      'vehicleLabel': instance.vehicleLabel,
    };
