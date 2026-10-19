// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationRequest _$ApplicationRequestFromJson(Map<String, dynamic> json) =>
    ApplicationRequest(
      displayName: json['displayName'] as String,
      documents: (json['documents'] as List<dynamic>)
          .map((e) => DocumentIn.fromJson(e as Map<String, dynamic>))
          .toList(),
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      photoPath: json['photoPath'] as String,
      serviceArea:
          ServiceAreaIn.fromJson(json['serviceArea'] as Map<String, dynamic>),
      yearsExperience: (json['yearsExperience'] as num).toInt(),
    );

Map<String, dynamic> _$ApplicationRequestToJson(ApplicationRequest instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'documents': instance.documents,
      'languages': instance.languages,
      'photoPath': instance.photoPath,
      'serviceArea': instance.serviceArea,
      'yearsExperience': instance.yearsExperience,
    };
