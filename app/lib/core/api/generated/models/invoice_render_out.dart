// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'invoice_render_out.g.dart';

@JsonSerializable()
class InvoiceRenderOut {
  const InvoiceRenderOut({
    required this.number,
    required this.version,
    this.ok = true,
  });
  
  factory InvoiceRenderOut.fromJson(Map<String, Object?> json) => _$InvoiceRenderOutFromJson(json);
  
  final String number;
  final bool ok;
  final int version;

  Map<String, Object?> toJson() => _$InvoiceRenderOutToJson(this);
}
