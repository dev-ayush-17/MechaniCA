// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationRequest _$ApplicationRequestFromJson(Map<String, dynamic> json) =>
    ApplicationRequest(
      displayName: json['displayName'] as String,
      photoPath: json['photoPath'] as String,
      yearsExperience: (json['yearsExperience'] as num).toInt(),
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      serviceArea:
          ServiceAreaIn.fromJson(json['serviceArea'] as Map<String, dynamic>),
      documents: (json['documents'] as List<dynamic>)
          .map((e) => DocumentIn.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ApplicationRequestToJson(ApplicationRequest instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'photoPath': instance.photoPath,
      'yearsExperience': instance.yearsExperience,
      'languages': instance.languages,
      'serviceArea': instance.serviceArea,
      'documents': instance.documents,
    };
