// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactOut _$ContactOutFromJson(Map<String, dynamic> json) => ContactOut(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneE164: json['phoneE164'] as String,
    );

Map<String, dynamic> _$ContactOutToJson(ContactOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phoneE164': instance.phoneE164,
    };
