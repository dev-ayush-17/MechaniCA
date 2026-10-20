// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_line_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceLineOut _$InvoiceLineOutFromJson(Map<String, dynamic> json) =>
    InvoiceLineOut(
      amountPaise: (json['amountPaise'] as num).toInt(),
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$InvoiceLineOutToJson(InvoiceLineOut instance) =>
    <String, dynamic>{
      'amountPaise': instance.amountPaise,
      'name': instance.name,
      'quantity': instance.quantity,
    };
