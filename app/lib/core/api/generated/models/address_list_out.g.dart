// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressListOut _$AddressListOutFromJson(Map<String, dynamic> json) =>
    AddressListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => AddressOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AddressListOutToJson(AddressListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
