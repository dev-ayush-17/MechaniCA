// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressOut _$AddressOutFromJson(Map<String, dynamic> json) => AddressOut(
      city: json['city'] as String,
      id: json['id'] as String,
      isDefault: json['isDefault'] as bool,
      label: json['label'] as String,
      lat: json['lat'] as num,
      line1: json['line1'] as String,
      lng: json['lng'] as num,
      ownerId: json['ownerId'] as String,
      pincode: json['pincode'] as String,
      landmark: json['landmark'] as String?,
    );

Map<String, dynamic> _$AddressOutToJson(AddressOut instance) =>
    <String, dynamic>{
      'city': instance.city,
      'id': instance.id,
      'isDefault': instance.isDefault,
      'label': instance.label,
      'landmark': instance.landmark,
      'lat': instance.lat,
      'line1': instance.line1,
      'lng': instance.lng,
      'ownerId': instance.ownerId,
      'pincode': instance.pincode,
    };
