// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_address_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchAddressRequest _$PatchAddressRequestFromJson(Map<String, dynamic> json) =>
    PatchAddressRequest(
      city: json['city'] as String?,
      isDefault: json['isDefault'] as bool?,
      label: json['label'] as String?,
      landmark: json['landmark'] as String?,
      lat: json['lat'] as num?,
      line1: json['line1'] as String?,
      lng: json['lng'] as num?,
      pincode: json['pincode'] as String?,
    );

Map<String, dynamic> _$PatchAddressRequestToJson(
        PatchAddressRequest instance) =>
    <String, dynamic>{
      'city': instance.city,
      'isDefault': instance.isDefault,
      'label': instance.label,
      'landmark': instance.landmark,
      'lat': instance.lat,
      'line1': instance.line1,
      'lng': instance.lng,
      'pincode': instance.pincode,
    };
