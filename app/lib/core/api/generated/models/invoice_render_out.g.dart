// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_render_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceRenderOut _$InvoiceRenderOutFromJson(Map<String, dynamic> json) =>
    InvoiceRenderOut(
      number: json['number'] as String,
      version: (json['version'] as num).toInt(),
      ok: json['ok'] as bool? ?? true,
    );

Map<String, dynamic> _$InvoiceRenderOutToJson(InvoiceRenderOut instance) =>
    <String, dynamic>{
      'number': instance.number,
      'ok': instance.ok,
      'version': instance.version,
    };
