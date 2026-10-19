// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentIn _$DocumentInFromJson(Map<String, dynamic> json) => DocumentIn(
      kind: DocumentKind.fromJson(json['kind'] as String),
      storagePath: json['storagePath'] as String,
    );

Map<String, dynamic> _$DocumentInToJson(DocumentIn instance) =>
    <String, dynamic>{
      'kind': _$DocumentKindEnumMap[instance.kind]!,
      'storagePath': instance.storagePath,
    };

const _$DocumentKindEnumMap = {
  DocumentKind.licence: 'licence',
  DocumentKind.governmentId: 'government_id',
  DocumentKind.selfie: 'selfie',
  DocumentKind.$unknown: r'$unknown',
};
