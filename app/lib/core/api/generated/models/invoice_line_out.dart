// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'invoice_line_out.g.dart';

@JsonSerializable()
class InvoiceLineOut {
  const InvoiceLineOut({
    required this.amountPaise,
    required this.name,
    required this.quantity,
  });
  
  factory InvoiceLineOut.fromJson(Map<String, Object?> json) => _$InvoiceLineOutFromJson(json);
  
  final int amountPaise;
  final String name;
  final int quantity;

  Map<String, Object?> toJson() => _$InvoiceLineOutToJson(this);
}
