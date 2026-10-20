// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_list_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentListOut _$DocumentListOutFromJson(Map<String, dynamic> json) =>
    DocumentListOut(
      items: (json['items'] as List<dynamic>)
          .map((e) => DocumentOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DocumentListOutToJson(DocumentListOut instance) =>
    <String, dynamic>{
      'items': instance.items,
    };
