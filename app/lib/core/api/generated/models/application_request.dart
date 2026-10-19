// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_in.dart';
import 'service_area_in.dart';

part 'application_request.g.dart';

@JsonSerializable()
class ApplicationRequest {
  const ApplicationRequest({
    required this.displayName,
    required this.photoPath,
    required this.yearsExperience,
    required this.languages,
    required this.serviceArea,
    required this.documents,
  });
  
  factory ApplicationRequest.fromJson(Map<String, Object?> json) => _$ApplicationRequestFromJson(json);
  
  final String displayName;
  final String photoPath;
  final int yearsExperience;
  final List<String> languages;
  final ServiceAreaIn serviceArea;
  final List<DocumentIn> documents;

  Map<String, Object?> toJson() => _$ApplicationRequestToJson(this);
}
