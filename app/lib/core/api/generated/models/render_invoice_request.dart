// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'render_invoice_request.g.dart';

@JsonSerializable()
class RenderInvoiceRequest {
  const RenderInvoiceRequest({
    required this.bookingId,
  });
  
  factory RenderInvoiceRequest.fromJson(Map<String, Object?> json) => _$RenderInvoiceRequestFromJson(json);
  
  final String bookingId;

  Map<String, Object?> toJson() => _$RenderInvoiceRequestToJson(this);
}
