// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/invoice_out.dart';

part 'invoices_client.g.dart';

@RestApi()
abstract class InvoicesClient {
  factory InvoicesClient(Dio dio, {String? baseUrl}) = _InvoicesClient;

  /// Get Invoice
  @GET('/v1/invoices/{booking_id}')
  Future<InvoiceOut> getInvoiceV1InvoicesBookingIdGet({
    @Path('booking_id') required String bookingId,
    @Header('authorization') String? authorization,
  });
}
