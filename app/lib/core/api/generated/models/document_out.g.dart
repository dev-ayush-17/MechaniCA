// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentOut _$DocumentOutFromJson(Map<String, dynamic> json) => DocumentOut(
      id: json['id'] as String,
      kind: json['kind'] as String,
      storagePath: json['storagePath'] as String,
    );

Map<String, dynamic> _$DocumentOutToJson(DocumentOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'storagePath': instance.storagePath,
    };
