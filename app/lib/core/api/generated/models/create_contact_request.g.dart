// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_contact_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateContactRequest _$CreateContactRequestFromJson(
        Map<String, dynamic> json) =>
    CreateContactRequest(
      name: json['name'] as String,
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$CreateContactRequestToJson(
        CreateContactRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
    };
