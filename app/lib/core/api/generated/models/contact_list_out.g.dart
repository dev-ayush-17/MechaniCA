// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactListOut _$ContactListOutFromJson(Map<String, dynamic> json) =>
    ContactListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => ContactOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ContactListOutToJson(ContactListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
