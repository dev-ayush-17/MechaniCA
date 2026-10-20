// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invoice_line_out.dart';

part 'invoice_out.g.dart';

@JsonSerializable()
class InvoiceOut {
  const InvoiceOut({
    required this.bookingId,
    required this.cgstPaise,
    required this.createdAt,
    required this.customerName,
    required this.downloadUrl,
    required this.gstin,
    required this.lines,
    required this.mechanicDisplayName,
    required this.number,
    required this.paymentMethod,
    required this.sgstPaise,
    required this.totalPaise,
    required this.vehicleRegistration,
    required this.version,
  });
  
  factory InvoiceOut.fromJson(Map<String, Object?> json) => _$InvoiceOutFromJson(json);
  
  final String bookingId;
  final int cgstPaise;
  final DateTime createdAt;
  final String customerName;
  final String downloadUrl;
  final String gstin;
  final List<InvoiceLineOut> lines;
  final String mechanicDisplayName;
  final String number;
  final String paymentMethod;
  final int sgstPaise;
  final int totalPaise;
  final String vehicleRegistration;
  final int version;

  Map<String, Object?> toJson() => _$InvoiceOutToJson(this);
}
