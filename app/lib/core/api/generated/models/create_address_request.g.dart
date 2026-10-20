// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_address_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAddressRequest _$CreateAddressRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAddressRequest(
      city: json['city'] as String,
      label: json['label'] as String,
      lat: json['lat'] as num,
      line1: json['line1'] as String,
      lng: json['lng'] as num,
      pincode: json['pincode'] as String,
      landmark: json['landmark'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$CreateAddressRequestToJson(
        CreateAddressRequest instance) =>
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
